"""Shared authoring contracts, compiler parity, and regression of missing targets.
Runs entirely in memory; never builds or overwrites project assets.
"""
from pathlib import Path
import copy
import json
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import content_tools as content
from content_contract import dialogue_errors, logic_errors
import sync_content_schema


def browser_project(c, logic):
    return {"world": c["world"], "charactersDoc": {"characters": c["characters"]},
            "casesDoc": {"cases": c["cases"]}, "tasksDoc": {"tasks": c["tasks"]},
            "levelsDoc": c["levels_doc"], "logicDoc": logic}


def main():
    assert sync_content_schema.BROWSER.read_text(encoding='utf-8') == sync_content_schema.expected(), 'run tools/sync_content_schema.py'
    node = shutil.which("node")
    if not node:
        raise RuntimeError("Node.js is required for Python/editor publication parity checks")
    fixtures = json.loads((ROOT / "tests/fixtures/content-contract.json").read_text(encoding="utf-8"))
    base = content.load_content()
    logic = content.read_json(content.LOGIC_PATH)
    total = 0
    for label, validator in [("dialogue", dialogue_errors), ("logic", logic_errors)]:
        for fixture in fixtures[label]:
            errors = validator(fixture["value"])
            assert (not errors) == fixture["valid"], (fixture["name"], errors)
            if fixture.get("code"):
                assert fixture["code"] in errors, (fixture["name"], errors)
            total += 1
    variants = [("current", base)]
    # Allocation checks are Python-side only (the editor preserves but does not
    # edit the allocation block), so they get direct assertions instead of JS parity.
    bad_alloc = copy.deepcopy(base)
    bad_alloc["world"]["allocation"]["caps"]["energy"] = 99
    assert any("allocation.caps.energy" in e for e in content.validate_content(bad_alloc))
    bad_favor = copy.deepcopy(base)
    bad_favor["world"]["allocation"]["visitors"][0]["options"][0]["favor"]["nobody"] = 1
    assert any("unknown favor role" in e for e in content.validate_content(bad_favor))
    bad_visitor = copy.deepcopy(base)
    bad_visitor["world"]["allocation"]["transitions"][0]["visitors"] = ["missing-visitor"]
    assert any("unknown visitor" in e for e in content.validate_content(bad_visitor))
    for fixture in fixtures["dialogue"]:
        c = copy.deepcopy(base)
        c["cases"][0]["dialogue"] = fixture["value"]
        variants.append((fixture["name"], c))
    for fixture in fixtures["project"]:
        c = copy.deepcopy(base)
        target = c
        for part in fixture["path"][:-1]:
            target = target[part]
        value = fixture.get("value")
        if "copy" in fixture:
            value = c
            for part in fixture["copy"]:
                value = value[part]
        target[fixture["path"][-1]] = copy.deepcopy(value)
        assert (not content.validate_content(c)) == fixture["valid"], fixture["name"]
        variants.append((fixture["name"], c))
        total += 1
    for name, c in variants:
        result = subprocess.run([node, str(ROOT / "tests/editor_contract.cjs")],
            input=json.dumps({"project": browser_project(c, logic), "fixtures": fixtures}),
            capture_output=True, text=True, encoding="utf-8", timeout=30)
        assert result.returncode == 0, result.stderr
        js = json.loads(result.stdout)
        for label, validator in [("dialogue", dialogue_errors), ("logic", logic_errors)]:
            expected = [validator(f["value"]) for f in fixtures[label]]
            assert js[label] == expected, (name, label, js[label], expected)
        errors = content.validate_content(c)
        assert bool(errors) == bool(js["errors"]), (name, errors, js["errors"])
        if not errors:
            data, requests, compile_errors = content.compile_content(c)
            assert not compile_errors
            assert data == js["compiled"]["data"], (name, "data compiler mismatch")
            assert requests == js["compiled"]["requests"], (name, "request compiler mismatch")
    print(f"CONTENT CONTRACT ok shared={total} project_variants={len(variants)}")


if __name__ == "__main__":
    main()
