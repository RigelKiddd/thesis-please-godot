#!/usr/bin/env python3
"""Modular content pipeline for THESIS, PLEASE.

Canonical authoring data lives in ``content/``:

  world.json       chapter-wide rules, tabs, extra materials, outcomes, night scenes
  characters.json  reusable people: name, student number, major, portrait, look
  cases.json       thesis cases: title, abstract, references, dup report, form
  levels.json      ordered days and their queue slots (character + case + task)
  tasks.json       face-to-face administrative packets (documents, criteria, answer)
  logic.json       editor-only visual condition chains (not compiled into the game yet)

The game still reads ``assets/data.json`` and ``assets/requests.json`` so the
runtime stays compatible.  Run this tool after editing content::

    python tools/content_tools.py build
    python tools/content_tools.py validate
    python tools/content_tools.py check

``split`` is the one-time migration from the legacy assets and is safe to keep
for reference; it overwrites content/ and should not be used after authoring.
"""

from __future__ import annotations

import argparse
import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content"
ASSETS = ROOT / "assets"

DATA_PATH = ASSETS / "data.json"
REQUESTS_PATH = ASSETS / "requests.json"
LOGIC_PATH = CONTENT / "logic.json"

# level day -> queue slot -> task id.  Tasks are authored separately, but the
# attachment lives on the level slot so moving a student moves their business.
TASK_SLOTS = {
    (1, 0): "leave-d1-1d",
    (2, 0): "scholarship-d2-incentive",
    (3, 0): "scholarship-d3-national",
    (3, 1): "exchange-d3-exchange",
    (4, 1): "honors-d4-college",
    (4, 2): "honors-d4-school",
    (5, 0): "scholarship-d5-school",
    (5, 1): "lab-d5-access",
    (6, 0): "leave-d6-3d",
    (6, 2): "internship-d6-recommend",
    (7, 0): "leave-d7-7d",
    (7, 2): "honors-d7-province",
}

WORLD_FROM_LEGACY = {
    "meta": "meta",
    "RULE_GROUPS": "ruleGroups",
    "TABS": "tabs",
    "EXTRA_MATERIALS": "extraMaterials",
    "OUTCOMES": "outcomes",
    "REF_POOL": "refPool",
    "NIGHT_SCENES": "nightScenes",
    "audits": "audits",
    "ALLOCATION": "allocation",
    "COLLEGE_GROUPS": "collegeGroups",
}
WORLD_TO_LEGACY = {v: k for k, v in WORLD_FROM_LEGACY.items()}


def read_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def stable_id(prefix: str, value: str) -> str:
    return f"{prefix}-{value}"


# ---------------------------------------------------------------------------
# split: legacy assets -> modular content
# ---------------------------------------------------------------------------
def split() -> None:
    data = read_json(DATA_PATH)
    requests = read_json(REQUESTS_PATH).get("requests", [])

    world = {"schema": 1}
    for legacy, modern in WORLD_FROM_LEGACY.items():
        if legacy in data:
            world[modern] = data[legacy]
    write_json(CONTENT / "world.json", world)

    characters: list[dict] = []
    cases: list[dict] = []
    levels: list[dict] = []
    seen_chars: set[str] = set()
    seen_cases: set[str] = set()

    for day_i, day in enumerate(data.get("DAYS", [])):
        slots = []
        for stu_i, s in enumerate(day.get("students", [])):
            official = s.get("official", {})
            student_no = str(s.get("id") or official.get("id") or f"{day_i + 1}{stu_i + 1}")
            char_id = stable_id("char", student_no)
            case_id = stable_id("case", student_no)
            if char_id in seen_chars:
                char_id = f"{char_id}-{day_i + 1}{stu_i + 1}"
            if case_id in seen_cases:
                case_id = f"{case_id}-{day_i + 1}{stu_i + 1}"
            seen_chars.add(char_id)
            seen_cases.add(case_id)

            char = {
                "id": char_id,
                "studentNo": student_no,
                "name": str(official.get("name") or s.get("name") or ""),
                "major": str(official.get("major") or ""),
                "college": str(official.get("college") or ""),
                "clazz": str(official.get("clazz") or ""),
                "grade": str(official.get("grade") or ""),
                "advisor": str(official.get("advisor") or ""),
                "portrait": "d%ds%d" % (day_i + 1, stu_i + 1),
                "look": s.get("look", {}),
            }
            characters.append(char)

            cover = s.get("cover", {})
            cover_overrides = {}
            for key in ("name", "id", "major", "college", "clazz"):
                if key in cover and cover.get(key) != official.get(key):
                    cover_overrides[key] = cover.get(key)
            dup = s.get("dup", {})
            dup_overrides = {}
            for key in ("name", "id"):
                if key in dup and dup.get(key) != official.get(key):
                    dup_overrides[key] = dup.get(key)

            case = {
                "id": case_id,
                "title": s.get("title", ""),
                "abstractTitle": s.get("abstractTitle", ""),
                "abstractChars": s.get("abstractChars", 0),
                "excerpt": s.get("excerpt", ""),
                "keywords": s.get("keywords", []),
                "refs": s.get("refs", []),
                "body": s.get("body", {}),
                "form": s.get("form", {}),
                "line": s.get("line", ""),
                "cover": {"overrides": cover_overrides},
                "dup": {
                    "rate": dup.get("rate", 0.0),
                    "reportNo": dup.get("reportNo", ""),
                    "seal": dup.get("seal", True),
                    "date": dup.get("date", ""),
                    "system": dup.get("system", ""),
                    "overrides": dup_overrides,
                },
            }
            if s.get("chat") is not None:
                case["chat"] = s["chat"]
            if s.get("dialogue") is not None:
                case["dialogue"] = s["dialogue"]
            cases.append(case)
            slots.append({
                "characterId": char_id,
                "caseId": case_id,
                "taskId": TASK_SLOTS.get((day_i + 1, stu_i)),
            })

        level = {
            "id": f"level-{day_i + 1}",
            "day": day_i + 1,
            "date": day.get("date", ""),
            "weekday": day.get("weekday", ""),
            "shortDate": day.get("shortDate", ""),
            "theme": day.get("theme", ""),
            "notice": day.get("notice", ""),
            "queue": slots,
        }
        levels.append(level)

    write_json(CONTENT / "characters.json", {"schema": 1, "characters": characters})
    write_json(CONTENT / "cases.json", {"schema": 1, "cases": cases})
    write_json(CONTENT / "levels.json", {
        "schema": 1,
        "chapter": {
            "id": "chapter-1",
            "title": "第一周",
            "startDate": str(data.get("DAYS", [{}])[0].get("date", "")),
        },
        "levels": levels,
    })

    tasks = []
    for r in requests:
        task = copy.deepcopy(r)
        # The runtime resolves day/index from the level slot at build time.
        task.pop("day", None)
        task.pop("applicantIndex", None)
        task.pop("applicant", None)
        task.pop("studentId", None)
        task.pop("major", None)
        tasks.append(task)
    write_json(CONTENT / "tasks.json", {"schema": 1, "tasks": tasks})
    print("SPLIT ok characters=%d cases=%d levels=%d tasks=%d"
          % (len(characters), len(cases), len(levels), len(tasks)))


# ---------------------------------------------------------------------------
# build: modular content -> runtime assets
# ---------------------------------------------------------------------------
def load_content() -> dict:
    def collection(filename, key):
        doc = read_json(CONTENT / filename)
        return doc.get(key) if isinstance(doc, dict) else None
    return {
        "world": read_json(CONTENT / "world.json"),
        "characters": collection("characters.json", "characters"),
        "cases": collection("cases.json", "cases"),
        "levels_doc": read_json(CONTENT / "levels.json"),
        "tasks": collection("tasks.json", "tasks"),
    }


def merge_student(char: dict, case: dict) -> dict:
    official = {
        "name": char.get("name", ""),
        "id": char.get("studentNo", ""),
        "major": char.get("major", ""),
        "college": char.get("college", ""),
        "clazz": char.get("clazz", ""),
        "grade": char.get("grade", ""),
        "advisor": char.get("advisor", ""),
        "advisorTitle": char.get("advisorTitle", ""),
        "advisorOffice": char.get("advisorOffice", ""),
        "director": char.get("director", ""),
        "directorTitle": char.get("directorTitle", ""),
        "collegeGroup": char.get("collegeGroup", ""),
    }
    cover = {
        "title": case.get("title", ""),
        "name": official["name"],
        "id": official["id"],
        "major": official["major"],
        "college": official["college"],
        "clazz": official["clazz"],
    }
    cover.update(case.get("cover", {}).get("overrides", {}))
    dup_src = case.get("dup", {})
    dup = {
        "rate": dup_src.get("rate", 0.0),
        "name": official["name"],
        "id": official["id"],
        "reportNo": dup_src.get("reportNo", ""),
        "seal": dup_src.get("seal", True),
        "date": dup_src.get("date", ""),
        "system": dup_src.get("system", ""),
    }
    dup.update(dup_src.get("overrides", {}))

    student = {
        "name": official["name"],
        "id": official["id"],
        "title": case.get("title", ""),
        "abstractTitle": case.get("abstractTitle", ""),
        "abstractChars": case.get("abstractChars", 0),
        "excerpt": case.get("excerpt", ""),
        "keywords": case.get("keywords", []),
        "line": case.get("line", ""),
        "look": char.get("look", {}),
        "official": official,
        "cover": cover,
        "refs": case.get("refs", []),
        "body": case.get("body", {}),
        "dup": dup,
        "form": case.get("form", {}),
    }
    if case.get("chat") is not None:
        student["chat"] = case["chat"]
    if case.get("dialogue") is not None:
        student["dialogue"] = case["dialogue"]
    return student


def compile_content(content: dict) -> tuple[dict, dict, list[str]]:
    errors: list[str] = []
    chars = {str(c.get("id")): c for c in content["characters"]}
    cases = {str(c.get("id")): c for c in content["cases"]}
    tasks = {str(t.get("id")): t for t in content["tasks"]}

    days = []
    requests_out = []
    for level in content["levels_doc"].get("levels", []):
        students = []
        for slot in level.get("queue", []):
            cid = str(slot.get("characterId", ""))
            case_id = str(slot.get("caseId", ""))
            if cid not in chars:
                errors.append(f"{level.get('id')}: missing character {cid}")
                continue
            if case_id not in cases:
                errors.append(f"{level.get('id')}: missing case {case_id}")
                continue
            students.append(merge_student(chars[cid], cases[case_id]))
            task_id = slot.get("taskId")
            if task_id:
                if str(task_id) not in tasks:
                    errors.append(f"{level.get('id')}: missing task {task_id}")
                    continue
                task = copy.deepcopy(tasks[str(task_id)])
                dup_slot = any(
                    t.get("_taskId") == task_id for t in requests_out
                )
                if dup_slot:
                    errors.append(f"task {task_id} is attached to more than one slot")
                task["_taskId"] = task_id
                task["day"] = int(level.get("day", 1))
                task["applicantIndex"] = len(students) - 1
                task["applicantId"] = str(chars[cid].get("studentNo", ""))
                requests_out.append(task)
        days.append({
            "weekday": level.get("weekday", ""),
            "date": level.get("date", ""),
            "shortDate": level.get("shortDate", ""),
            "theme": level.get("theme", ""),
            "notice": level.get("notice", ""),
            "students": students,
        })

    world = content["world"]
    data = {}
    for legacy, modern in WORLD_FROM_LEGACY.items():
        if modern in world:
            data[legacy] = copy.deepcopy(world[modern])
    data["DAYS"] = days

    for r in requests_out:
        r.pop("_taskId", None)

    return data, {"requests": requests_out}, errors


def walk_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, list):
        for item in value:
            yield from walk_strings(item)
    elif isinstance(value, dict):
        for item in value.values():
            yield from walk_strings(item)


from content_contract import dialogue_errors, logic_errors, shape_errors


def validate_content(content: dict) -> list[str]:
    errors = shape_errors(content)
    if errors:
        return errors
    for case in content["cases"]:
        errors.extend(f"case {case.get('id')}: {e}" for e in dialogue_errors(case.get("dialogue")))
    chars = content["characters"]
    cases = content["cases"]
    tasks = content["tasks"]
    levels = content["levels_doc"].get("levels", [])
    errors.extend(allocation_errors(content["world"], tasks, content["world"].get("nightScenes", [])))
    errors.extend(college_errors(content["world"], chars, cases, content["levels_doc"]))

    for char in chars:
        if not char.get("name"):
            errors.append(f"character {char.get('id')}: missing name")

    for label, rows in (("character", chars), ("case", cases), ("task", tasks), ("level", levels)):
        seen = set()
        for row in rows:
            rid = str(row.get("id", ""))
            if not rid:
                errors.append(f"{label}: empty id")
            elif rid in seen:
                errors.append(f"{label}: duplicate id {rid}")
            seen.add(rid)

    char_ids = {str(c.get("id")) for c in chars}
    case_ids = {str(c.get("id")) for c in cases}
    task_ids = {str(t.get("id")) for t in tasks}
    task_slots: dict[str, str] = {}
    task_count = 0

    for level in levels:
        queue = level.get("queue", [])
        if not queue:
            errors.append(f"{level.get('id')}: empty queue")
        for index, slot in enumerate(queue):
            cid = str(slot.get("characterId", ""))
            case_id = str(slot.get("caseId", ""))
            if cid not in char_ids:
                errors.append(f"{level.get('id')}[{index}]: unknown character {cid}")
            if case_id not in case_ids:
                errors.append(f"{level.get('id')}[{index}]: unknown case {case_id}")
            task_id = slot.get("taskId")
            if task_id:
                task_count += 1
                if str(task_id) not in task_ids:
                    errors.append(f"{level.get('id')}[{index}]: unknown task {task_id}")
                if str(task_id) in task_slots:
                    errors.append(f"task {task_id} used twice")
                task_slots[str(task_id)] = f"{level.get('id')}[{index}]"

    for task in tasks:
        tid = str(task.get("id", ""))
        expected = str(task.get("expected", ""))
        if expected not in {"approve", "return"}:
            errors.append(f"{tid}: expected must be approve/return")
        docs = task.get("documents", [])
        if not docs:
            errors.append(f"{tid}: no documents")
        doc_ids = set()
        for doc in docs:
            did = str(doc.get("id", ""))
            if not did:
                errors.append(f"{tid}: document with empty id")
            elif did in doc_ids:
                errors.append(f"{tid}: duplicate document id {did}")
            doc_ids.add(did)
            if str(doc.get("style", "")) not in {
                "certificate", "cardstock", "carbonless", "sealed", "mimeo",
                "student_id", "id_card", "scholarship", "admission", "ledger",
                "index_card", "passport", "boarding",
            }:
                errors.append(f"{tid}/{did}: unknown style {doc.get('style')}")
        for check in task.get("checks", []):
            source = check.get("source")
            if source and str(source) not in doc_ids:
                errors.append(f"{tid}: check source {source} is not a document")
        for text in walk_strings(task):
            if "{{" in text and "}}" not in text:
                errors.append(f"{tid}: malformed placeholder in {text[:40]!r}")

    if task_count != len(tasks):
        errors.append(f"{task_count} task slots but {len(tasks)} task definitions")
    return errors


def _favor_errors(where: str, favor, role_ids: set[str]) -> list[str]:
    if favor is None:
        return []
    if not isinstance(favor, dict):
        return [f"{where}: favor must be an object"]
    errors = []
    for role, delta in favor.items():
        if str(role) not in role_ids:
            errors.append(f"{where}: unknown favor role {role}")
        if type(delta) not in (int, float) or delta == 0:
            errors.append(f"{where}: favor {role} must be a non-zero number")
    return errors


def allocation_errors(world: dict, tasks: list[dict], night_scenes: list[dict]) -> list[str]:
    """Validate the between-days allocation phase authored in world.allocation."""
    alloc = world.get("allocation")
    if alloc is None:
        return []
    if not isinstance(alloc, dict):
        return ["allocation: not an object"]
    errors: list[str] = []

    roles = alloc.get("roles", [])
    projects = alloc.get("projects", [])
    transitions = alloc.get("transitions", [])
    visitors = alloc.get("visitors", [])
    if not isinstance(roles, list) or not roles:
        errors.append("allocation: roles must be a non-empty array")
        roles = []
    if not isinstance(projects, list) or not projects:
        errors.append("allocation: projects must be a non-empty array")
        projects = []
    if not isinstance(transitions, list) or not transitions:
        errors.append("allocation: transitions must be a non-empty array")
        transitions = []
    if not isinstance(visitors, list) or not visitors:
        errors.append("allocation: visitors must be a non-empty array")
        visitors = []

    role_ids: set[str] = set()
    for role in roles:
        if not isinstance(role, dict):
            errors.append("allocation.roles: entry is not an object")
            continue
        rid = str(role.get("id", ""))
        if not rid:
            errors.append("allocation.roles: empty id")
        elif rid in role_ids:
            errors.append(f"allocation.roles: duplicate id {rid}")
        role_ids.add(rid)
        for key in ("name", "role", "seal"):
            if not str(role.get(key, "")).strip():
                errors.append(f"allocation.roles.{rid}: missing {key}")
        perk = role.get("perk", {})
        if not isinstance(perk, dict):
            errors.append(f"allocation.roles.{rid}: perk must be an object")
        elif int(perk.get("at", 1)) < 1:
            errors.append(f"allocation.roles.{rid}: perk.at must be >= 1")
        elif not ({"energy", "money", "perf"} & set(perk)):
            errors.append(f"allocation.roles.{rid}: perk needs energy/money/perf")

    levels = alloc.get("favorLevels", [])
    if not isinstance(levels, list) or not levels:
        errors.append("allocation: favorLevels must be a non-empty array")
    else:
        last = -1
        for row in levels:
            if not isinstance(row, dict):
                errors.append("allocation.favorLevels: entry is not an object")
                continue
            at = int(row.get("at", -1))
            if at <= last:
                errors.append("allocation.favorLevels: 'at' must increase")
            last = at
            if not str(row.get("label", "")).strip():
                errors.append("allocation.favorLevels: missing label")

    caps = alloc.get("caps", {})
    if not isinstance(caps, dict):
        errors.append("allocation.caps: must be an object")
        caps = {}
    project_ids: set[str] = set()
    coin_caps = {"energy": 0, "money": 0}
    for project in projects:
        if not isinstance(project, dict):
            errors.append("allocation.projects: entry is not an object")
            continue
        pid = str(project.get("id", ""))
        if not pid:
            errors.append("allocation.projects: empty id")
        elif pid in project_ids:
            errors.append(f"allocation.projects: duplicate id {pid}")
        project_ids.add(pid)
        coin = str(project.get("coin", ""))
        if coin not in coin_caps:
            errors.append(f"allocation.projects.{pid}: coin must be energy/money")
            continue
        cap = project.get("cap", 0)
        if type(cap) not in (int, float) or int(cap) != cap or cap < 1:
            errors.append(f"allocation.projects.{pid}: cap must be a positive integer")
            continue
        coin_caps[coin] += int(cap)
        if not str(project.get("label", "")).strip():
            errors.append(f"allocation.projects.{pid}: missing label")
        if type(project.get("perf", 0)) not in (int, float):
            errors.append(f"allocation.projects.{pid}: perf must be a number")
        errors.extend(_favor_errors(f"allocation.projects.{pid}", project.get("favor"), role_ids))
        if int(project.get("repAtCap", 0)) != 0 and int(cap) < 2:
            errors.append(f"allocation.projects.{pid}: repAtCap needs cap >= 2")
    for coin, total in coin_caps.items():
        if int(caps.get(coin, -1)) != total:
            errors.append(f"allocation.caps.{coin}: expected {total} from project caps")

    visitor_ids: set[str] = set()
    visitor_roles: set[str] = set()
    for visitor in visitors:
        if not isinstance(visitor, dict):
            errors.append("allocation.visitors: entry is not an object")
            continue
        vid = str(visitor.get("id", ""))
        if not vid:
            errors.append("allocation.visitors: empty id")
        elif vid in visitor_ids:
            errors.append(f"allocation.visitors: duplicate id {vid}")
        visitor_ids.add(vid)
        rid = str(visitor.get("role", ""))
        if rid not in role_ids:
            errors.append(f"allocation.visitors.{vid}: unknown role {rid}")
        else:
            visitor_roles.add(rid)
        if not str(visitor.get("title", "")).strip():
            errors.append(f"allocation.visitors.{vid}: missing title")
        if not isinstance(visitor.get("story", []), list) or not visitor.get("story"):
            errors.append(f"allocation.visitors.{vid}: missing story")
        options = visitor.get("options", [])
        if not isinstance(options, list) or not 2 <= len(options) <= 4:
            errors.append(f"allocation.visitors.{vid}: needs 2–4 options")
            continue
        for index, opt in enumerate(options):
            if not isinstance(opt, dict):
                errors.append(f"allocation.visitors.{vid}[{index}]: not an object")
                continue
            if not str(opt.get("label", "")).strip():
                errors.append(f"allocation.visitors.{vid}[{index}]: missing label")
            if str(opt.get("tag", "")) not in ("批", "驳", "缓"):
                errors.append(f"allocation.visitors.{vid}[{index}]: tag must be 批/驳/缓")
            if not str(opt.get("result", "")).strip():
                errors.append(f"allocation.visitors.{vid}[{index}]: missing result")
            errors.extend(_favor_errors(f"allocation.visitors.{vid}[{index}]", opt.get("favor"), role_ids))
            for key in ("energy", "money", "perf", "rep"):
                if type(opt.get(key, 0)) not in (int, float):
                    errors.append(f"allocation.visitors.{vid}[{index}]: {key} must be a number")

    for role in role_ids - visitor_roles:
        errors.append(f"allocation.roles.{role}: no visitor uses this role")

    seen_days: set[int] = set()
    for transition in transitions:
        if not isinstance(transition, dict):
            errors.append("allocation.transitions: entry is not an object")
            continue
        after = transition.get("afterDay", 0)
        if type(after) not in (int, float) or int(after) != after or after < 1:
            errors.append("allocation.transitions: afterDay must be a positive integer")
            continue
        after = int(after)
        if after in seen_days:
            errors.append(f"allocation.transitions: duplicate afterDay {after}")
        seen_days.add(after)
        for coin in coin_caps:
            base = transition.get(coin, 0)
            if type(base) not in (int, float) or base < 0 or base > caps.get(coin, 0):
                errors.append(f"allocation.transitions[{after}].{coin}: must be 0..{caps.get(coin, 0)}")
        for vid in transition.get("visitors", []):
            if str(vid) not in visitor_ids:
                errors.append(f"allocation.transitions[{after}]: unknown visitor {vid}")
    if seen_days and sorted(seen_days) != list(range(1, max(seen_days) + 1)):
        errors.append("allocation.transitions: afterDay must cover 1..N without gaps")

    for task in tasks:
        favor = task.get("favor")
        if favor is None:
            continue
        if not isinstance(favor, dict):
            errors.append(f"{task.get('id')}: favor must be an object")
            continue
        for action in ("approve", "return"):
            if action in favor:
                errors.extend(_favor_errors(f"{task.get('id')}.{action}", favor[action], role_ids))
    for scene in night_scenes:
        for index, opt in enumerate(scene.get("choice", {}).get("options", [])):
            errors.extend(_favor_errors(f"night{scene.get('day')}[{index}]", opt.get("favor"), role_ids))
    return errors


def college_errors(world: dict, characters: list[dict], cases: list[dict], levels_doc: dict) -> list[str]:
    """Validate per-college advisors/directors and their signature wiring."""
    data = world.get("collegeGroups")
    if data is None:
        return []
    if not isinstance(data, dict):
        return ["collegeGroups: not an object"]
    errors: list[str] = []
    groups = data.get("groups", [])
    if not isinstance(groups, list) or not groups:
        return ["collegeGroups.groups: must be a non-empty array"]
    if int(data.get("milestoneAt", 0)) < 1:
        errors.append("collegeGroups.milestoneAt: must be >= 1")
    if int(data.get("favorCap", 0)) < 1:
        errors.append("collegeGroups.favorCap: must be >= 1")

    group_by_id = {}
    group_by_college = {}
    for group in groups:
        if not isinstance(group, dict):
            errors.append("collegeGroups.groups: entry is not an object")
            continue
        gid = str(group.get("id", ""))
        if not gid:
            errors.append("collegeGroups.groups: empty id")
        elif gid in group_by_id:
            errors.append(f"collegeGroups.groups: duplicate id {gid}")
        group_by_id[gid] = group
        for key in ("label", "seal", "story", "letter"):
            if not str(group.get(key, "")).strip():
                errors.append(f"collegeGroups.{gid}: missing {key}")
        for role in ("advisor", "director"):
            person = group.get(role, {})
            if not isinstance(person, dict):
                errors.append(f"collegeGroups.{gid}.{role}: must be an object")
                continue
            for key in ("name", "title", "office", "seal"):
                if not str(person.get(key, "")).strip():
                    errors.append(f"collegeGroups.{gid}.{role}: missing {key}")
        for key in ("passPerf", "milestonePerf"):
            if type(group.get(key, None)) not in (int, float) or int(group.get(key, -1)) < 0:
                errors.append(f"collegeGroups.{gid}.{key}: must be a non-negative number")
        colleges = group.get("colleges", [])
        if not isinstance(colleges, list) or not colleges:
            errors.append(f"collegeGroups.{gid}: empty colleges")
            continue
        for college in colleges:
            name = str(college)
            if name in group_by_college:
                errors.append(f"collegeGroups: college mapped twice: {name}")
            group_by_college[name] = group

    char_by_id = {str(c.get("id", "")): c for c in characters}
    for char in characters:
        college = str(char.get("college", ""))
        group = group_by_college.get(college)
        if group is None:
            errors.append(f"character {char.get('id')}: college {college} is not in collegeGroups")
            continue
        gid = str(group.get("id", ""))
        if str(char.get("collegeGroup", "")) != gid:
            errors.append(f"character {char.get('id')}: collegeGroup should be {gid}")
        if str(char.get("advisor", "")) != str(group.get("advisor", {}).get("name", "")):
            errors.append(f"character {char.get('id')}: advisor does not match {gid}")
        if str(char.get("director", "")) != str(group.get("director", {}).get("name", "")):
            errors.append(f"character {char.get('id')}: director does not match {gid}")

    case_to_char = {}
    for level in levels_doc.get("levels", []):
        for slot in level.get("queue", []):
            case_to_char[str(slot.get("caseId", ""))] = str(slot.get("characterId", ""))
    for case in cases:
        char = char_by_id.get(case_to_char.get(str(case.get("id", "")), ""))
        if char is None:
            continue
        group = group_by_college.get(str(char.get("college", "")))
        if group is None:
            continue
        sigs = case.get("form", {}).get("signatures", {})
        if sigs.get("advisor") is not None and str(sigs.get("advisor")) != str(group["advisor"]["name"]):
            errors.append(f"case {case.get('id')}: advisor signature does not match college")
        if sigs.get("chair") is not None and str(sigs.get("chair")) != str(group["director"]["name"]):
            errors.append(f"case {case.get('id')}: chair signature does not match college")

    for college in group_by_college:
        if college not in {str(c.get("college", "")) for c in characters}:
            errors.append(f"collegeGroups: college {college} has no character")
    return errors


def validate_logic(path: Path = LOGIC_PATH) -> list[str]:
    if not path.exists():
        return []
    try:
        return logic_errors(read_json(path))
    except (ValueError, OSError) as exc:
        return [f"logic.json: {exc}"]


def build() -> int:
    content = load_content()
    errors = validate_content(content) + validate_logic()
    if errors:
        for e in errors:
            print("ERROR " + e)
        print(f"CONTENT BUILD failed errors={len(errors)}")
        return 1
    data, requests, compile_errors = compile_content(content)
    if compile_errors:
        for e in compile_errors:
            print("ERROR " + e)
        print(f"CONTENT BUILD failed errors={len(compile_errors)}")
        return 1
    write_json(DATA_PATH, data)
    write_json(REQUESTS_PATH, requests)
    print("CONTENT BUILD ok days=%d requests=%d"
          % (len(data.get("DAYS", [])), len(requests["requests"])))
    return 0


def check() -> int:
    content = load_content()
    errors = validate_content(content) + validate_logic()
    if errors:
        for e in errors:
            print("ERROR " + e)
        print(f"CONTENT CHECK failed errors={len(errors)}")
        return 1
    data, requests, compile_errors = compile_content(content)
    if compile_errors:
        for e in compile_errors:
            print("ERROR " + e)
        print(f"CONTENT CHECK failed errors={len(compile_errors)}")
        return 1
    current_data = read_json(DATA_PATH)
    current_requests = read_json(REQUESTS_PATH)
    if data != current_data:
        print("CONTENT CHECK failed: assets/data.json is stale")
        print("  run: python tools/content_tools.py build")
        return 1
    if requests != current_requests:
        print("CONTENT CHECK failed: assets/requests.json is stale")
        print("  run: python tools/content_tools.py build")
        return 1
    print("CONTENT CHECK ok characters=%d cases=%d levels=%d tasks=%d"
          % (len(content["characters"]), len(content["cases"]),
             len(content["levels_doc"].get("levels", [])), len(content["tasks"])))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["split", "build", "validate", "check"])
    args = parser.parse_args()
    if args.command == "split":
        split()
        return 0
    if args.command == "build":
        return build()
    if args.command == "validate":
        errors = validate_content(load_content()) + validate_logic()
        for e in errors:
            print("ERROR " + e)
        print("CONTENT VALIDATE " + ("ok" if not errors else f"failed errors={len(errors)}"))
        return 0 if not errors else 1
    return check()


if __name__ == "__main__":
    sys.exit(main())
