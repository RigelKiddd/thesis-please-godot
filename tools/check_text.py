#!/usr/bin/env python3
"""Text integrity checks for the Godot project.

Guards against the failure mode that hit Main.gd once: a UTF-8 file was read as
CP936 by a shell and written back as mojibake. Hard failures are:

  * invalid UTF-8
  * UTF-8 BOM (the project policy is BOM-less)
  * U+FFFD replacement characters
  * private-use-area characters
  * known CP936-mojibake substrings

It also samples Chinese string literals in Main.gd against the project corpus
(data.json, other scripts, README, reference HTML). Unknown characters are
reported as warnings; --strict turns them into failures.

Usage:
  python tools/check_text.py
  python tools/check_text.py --strict
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

TEXT_SUFFIXES = {".gd", ".md", ".json", ".cfg", ".godot", ".tscn", ".ps1", ".py", ".html", ".js", ".cjs"}
SKIP_DIRS = {".godot", ".tools", "_ref", "node_modules", "build", "tests/baseline", "_shots", ".git"}
MOJIBAKE = (
    "锟斤拷",
    "璁烘",
    "瀹℃",
    "鈥",
    "銆�",
    "锛�",
    "鐨�",
    "鏄",
    "浣犲",
    "璇蜂",
    "闇€",
    "寮€",
    "鍜屼",
    "涓€",
    "鍙",
    "杩",
    "鎴",
)
CHINESE_RUN = re.compile(r"[\u4e00-\u9fff]{2,}")
STRING_LITERAL = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"')


def is_pua(code: int) -> bool:
    return 0xE000 <= code <= 0xF8FF or 0xF0000 <= code <= 0xFFFFD


def iter_files(root: Path):
    for path in root.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        rel = path.relative_to(root)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if "baseline" in rel.parts:
            continue
        if path.name == "check_text.py":
            continue
        yield path


def hard_issues(path: Path, raw: bytes) -> list[str]:
    issues: list[str] = []
    if raw.startswith(b"\xef\xbb\xbf"):
        issues.append("UTF-8 BOM present")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        issues.append(f"invalid UTF-8 at byte {exc.start}")
        text = raw.decode("utf-8", "replace")
    for line_no, line in enumerate(text.splitlines(), 1):
        if "\ufffd" in line:
            issues.append(f"line {line_no}: U+FFFD replacement character")
        for ch in line:
            if is_pua(ord(ch)):
                issues.append(f"line {line_no}: private-use character U+{ord(ch):04X}")
                break
        for pat in MOJIBAKE:
            if pat in line:
                # Markdown may quote the pattern as an example in documentation.
                if path.suffix.lower() in {".md", ".html"}:
                    continue
                issues.append(f"line {line_no}: mojibake pattern {pat!r}")
                break
    return issues


def corpus_text(root: Path) -> str:
    parts: list[str] = []
    for path in iter_files(root):
        if path.name == "Main.gd" or path.suffix.lower() == ".html":
            continue
        try:
            parts.append(path.read_text(encoding="utf-8"))
        except UnicodeDecodeError:
            continue
    ref = root / "reference"
    if ref.is_dir():
        for path in ref.glob("*.html"):
            try:
                parts.append(path.read_text(encoding="utf-8"))
            except UnicodeDecodeError:
                continue
    return "\n".join(parts)


def string_samples(root: Path, corpus: str):
    path = root / "scripts" / "Main.gd"
    if not path.exists():
        return []
    warnings: list[str] = []
    known = set(ch for ch in corpus if "\u4e00" <= ch <= "\u9fff")
    seen: set[str] = set()
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        for match in STRING_LITERAL.finditer(line):
            literal = match.group(1)
            if not CHINESE_RUN.search(literal):
                continue
            for run in CHINESE_RUN.findall(literal):
                if run in seen:
                    continue
                seen.add(run)
                unknown = [ch for ch in run if ch not in known]
                if unknown:
                    warnings.append(f"line {line_no}: unknown char(s) {''.join(unknown)!r} in {run!r}")
    return warnings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[1]))
    parser.add_argument("--strict", action="store_true", help="treat string-sample warnings as failures")
    args = parser.parse_args()
    root = Path(args.root).resolve()

    failed = 0
    checked = 0
    for path in iter_files(root):
        checked += 1
        raw = path.read_bytes()
        issues = hard_issues(path, raw)
        if issues:
            failed += 1
            print(f"FAIL {path.relative_to(root)}")
            for issue in issues[:12]:
                print("  - " + issue.encode("ascii", "backslashreplace").decode("ascii"))

    warnings = string_samples(root, corpus_text(root))
    if warnings:
        print(f"WARN {len(warnings)} Chinese string sample(s) contain chars absent from the corpus:")
        for warning in warnings[:30]:
            print("  - " + warning.encode("ascii", "backslashreplace").decode("ascii"))
        if len(warnings) > 30:
            print(f"  ... {len(warnings) - 30} more")
        if args.strict:
            failed += 1

    if failed:
        print(f"TEXTCHECK FAILED ({failed} file/group issue(s), {checked} files checked)")
        return 1
    print(f"TEXTCHECK ok ({checked} files, {len(warnings)} sample warning(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())
