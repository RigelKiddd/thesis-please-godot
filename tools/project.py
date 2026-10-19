"""One entry point for validation, isolated tests, packaging and release.

python tools/project.py test [--skip-shots] [--state savecheck]
python tools/project.py build | pack | release | doctor
Godot: --godot, GODOT_BIN, tools/toolchain.local.json, .tools/godot, PATH.
No implicit dependency on a directory outside the checkout.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
CONFIG = json.loads((ROOT / "tools/toolchain.json").read_text(encoding="utf-8"))
CHECKS = {
    "architecturecheck": "ARCHITECTURECHECK ok",
    "rulecheck": "RULECHECK ok", "annotationcheck": "ANNOTCHECK ok",
    "chatcheck": "CHATCHECK ok", "chatmemory": "CHATMEM ok", "chatflow": "CHATFLOW ok",
    "chatdialogue": "CHATDIALOGUE ok", "savecheck": "SAVECHECK ok",
    "backupcheck": "BACKUPCHECK ok", "continuecheck": "CONTINUECHECK ok",
    "settingscheck": "SETTINGSCHECK ok", "titlesettings": "TITLESETTINGS ok",
    "routercheck": "ROUTERCHECK ok", "nightclickcheck": "NIGHTCLICKCHECK ok",
    "startcheck": "STARTCHECK ok",
    "requestcheck": "REQUESTCHECK ok", "requestflow": "REQUESTFLOW ok",
    "requestmulti": "REQUESTMULTI ok", "requestpacketcheck": "REQUESTPACKETCHECK ok",
    "stampcheck": "STAMPCHECK ok", "stylecheck": "STYLECHECK ok", "eventcheck": "EVENTCHECK ok",
    "facecheck": "FACECHECK ok", "facefuturecheck": "FACEFUTURECHECK ok",
    "metricscheck": "METRICSCHECK ok", "largetextcheck": "LARGETEXTCHECK ok",
    "portraitcheck": "PORTRAITCHECK ok", "inputreplay": "INPUTREPLAY ok",
    "allocationcheck": "ALLOCATIONCHECK ok",
    "collegecheck": "COLLEGECHECK ok",
    "smoke": "SMOKE ok", "docall": "DOCALL rendered 280", "storydocall": "STORYDOCALL rendered 21",
    "shotregress": "SHOTREGRESS ok",
}


def resolve_godot(explicit: str | None = None) -> Path:
    local = ROOT / "tools/toolchain.local.json"
    settings = json.loads(local.read_text(encoding="utf-8")) if local.exists() else {}
    configured = explicit or os.environ.get("GODOT_BIN") or settings.get("godot")
    if configured:
        path = Path(configured).expanduser()
        path = path if path.is_absolute() else ROOT / path
        if not path.is_file():
            raise RuntimeError(f"Configured Godot does not exist: {path}")
        return path.resolve()
    for folder in [ROOT / ".tools/godot", ROOT / "_tools/godot"]:
        candidates = sorted(folder.glob("*console.exe")) + sorted(folder.glob("Godot*"))
        for path in candidates:
            if path.is_file() and path.suffix.lower() in (".exe", "", ".x86_64"):
                return path
    for name in ["godot", "godot4"]:
        found = shutil.which(name)
        if found:
            return Path(found)
    raise RuntimeError("Godot missing. Set GODOT_BIN / --godot, or install it in .tools/godot.")


class Runner:
    def __init__(self, godot: Path):
        self.godot = godot
        self.output = ROOT / "build" / (time.strftime("check-%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:6])
        self.output.mkdir(parents=True)
        self.results = []
        self.skipped = []

    def command(self, name, command, token=None, timeout=90, engine=False):
        env = os.environ.copy()
        env["PYTHONUTF8"] = "1"
        env["THESIS_USER_DIR"] = str(self.output / "user-data" / name)
        temp = self.output / "temp" / name
        temp.mkdir(parents=True, exist_ok=True)
        env["TEMP"] = env["TMP"] = str(temp)
        if engine:
            command = [command[0], "--log-file", self.output / f"{name}.engine.log", *command[1:]]
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        try:
            result = subprocess.run([str(x) for x in command], cwd=ROOT, env=env,
                                    capture_output=True, text=True, encoding="utf-8", errors="replace",
                                    timeout=timeout, creationflags=flags)
            output = result.stdout + "\n" + result.stderr
            # Some installations emit this known certificate-store warning at
            # shutdown. No script/parse/resource errors are allowed through.
            significant = "\n".join(line for line in output.splitlines()
                if not ("certs.size()" in line or "Could not load certs" in line or "Failed to read the root certificate store." in line))
            errors = bool(re.search(r"SCRIPT ERROR:|Parse Error:|^ERROR:", significant, re.M))
            known_certificate = any(x in output for x in ["certs.size()", "Could not load certs", "Failed to read the root certificate store."])
            ok_exit = result.returncode == 0 or (result.returncode == 1 and engine and known_certificate and not errors)
            ok = ok_exit and not errors and (token is None or token in output)
        except subprocess.TimeoutExpired as exc:
            def decoded(value):
                return value.decode('utf-8', errors='replace') if isinstance(value, bytes) else (value or '')
            output = f"TIMEOUT after {timeout}s\n" + decoded(exc.stdout) + decoded(exc.stderr)
            ok = False
        (self.output / f"{name}.log").write_text(output, encoding="utf-8")
        self.results.append({"name": name, "passed": ok})
        self.report()
        print(f"{'PASS' if ok else 'FAIL'} {name}", flush=True)
        if not ok:
            failures = '\n'.join(line for line in output.splitlines() if re.search(r'ERROR|Error|failed|TIMEOUT', line))
            print(failures or output[-4000:], flush=True)
        return ok

    def report(self):
        (self.output / "results.json").write_text(json.dumps({
            "godot": str(self.godot), "checks": self.results,
            "skipped": self.skipped,
            "passed": all(x["passed"] for x in self.results),
        }, indent=2), encoding="utf-8")

    def state(self, state):
        args = [self.godot]
        if state != "shotregress":
            args.append("--headless")
        args += ["--path", ROOT, "res://tests/TestMain.tscn", "--", f"--state={state}"]
        return self.command(state, args, CHECKS[state], 180 if state == "shotregress" else 90, True)

    def content(self, build=False):
        commands = [("textcheck", "tools/check_text.py", []),
                    ("content-validate", "tools/content_tools.py", ["validate"])]
        if build:
            commands.append(("content-build", "tools/content_tools.py", ["build"]))
        commands.append(("contentcheck", "tools/content_tools.py", ["check"]))
        if (ROOT / "tests/test_content_contract.py").exists():
            commands.append(("content-contract", "tests/test_content_contract.py", []))
        for name, script, args in commands:
            if not self.command(name, [sys.executable, "-X", "utf8", script, *args]):
                return False
        return True

    def pack(self, release=False):
        suffix = ".exe" if release else ".pck"
        path = self.output / ("THESIS_PLEASE" + suffix)
        option = "--export-release" if release else "--export-pack"
        if not self.command("export" + suffix, [self.godot, "--headless", "--path", ROOT,
                            option, CONFIG["export_preset"], path], timeout=180, engine=True):
            return False
        if not path.is_file() or path.stat().st_size == 0:
            print("FAIL fresh export artifact missing", flush=True)
            self.results.append({"name": "export-artifact" + suffix, "passed": False})
            self.report()
            return False
        if release:
            console = path.with_suffix(".console.exe")
            command = [console if console.exists() else path, "--headless", "--", "--state=smoke"]
        else:
            command = [self.godot, "--headless", "--main-pack", path, "--", "--state=smoke"]
        if not self.command("exe-smoke" if release else "pck-smoke", command, "SMOKE ok", engine=True):
            return False
        (self.output / "artifact.json").write_text(json.dumps({
            "file": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size, "engine_version": CONFIG["godot_version"],
        }, indent=2), encoding="utf-8")
        print("EXPORT SMOKE PASSED" if release else "PACK SMOKE PASSED", flush=True)
        return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["setup", "doctor", "test", "build", "pack", "export", "release"])
    parser.add_argument("--godot")
    parser.add_argument("--skip-shots", action="store_true")
    parser.add_argument("--state", choices=list(CHECKS), action="append")
    args = parser.parse_args()
    if args.command == "release" and (args.state or args.skip_shots):
        parser.error("release always runs the complete suite; use test for targeted checks")
    try:
        if args.command == "setup":
            from install_toolchain import install
            install()
            return 0
        godot = resolve_godot(args.godot)
        version = subprocess.run([str(godot), "--version"], capture_output=True, text=True,
                                 timeout=15).stdout.strip()
        if not version.startswith(CONFIG["godot_version"] + "."):
            raise RuntimeError(f"Expected Godot {CONFIG['godot_version']}, found {version!r}")
        print(f"Godot {version}: {godot}", flush=True)
        if args.command == "doctor":
            return 0
        runner = Runner(godot)
        print(f"Logs and isolated user data: {runner.output}", flush=True)
        if args.command in ("pack", "export"):
            ok = runner.content() and runner.pack(release=args.command == "export")
        else:
            ok = runner.content(build=args.command in ("build", "release"))
            if ok and args.command in ("test", "release"):
                ok = runner.command("import", [godot, "--headless", "--path", ROOT, "--editor", "--quit"], timeout=180, engine=True)
                if not ok:
                    return 1
                states = args.state or list(CHECKS)
                if args.skip_shots and args.command != "release":
                    states = [s for s in states if s != "shotregress"]
                    runner.skipped.append("shotregress")
                    print("SKIP shotregress (explicit --skip-shots)", flush=True)
                for state in states:
                    # Continue independent tests to report all failures.
                    ok = runner.state(state) and ok
                if not args.state and ok:
                    ok = runner.pack()
            if args.command == "release" and ok:
                ok = runner.pack(release=True)
        print("CHECKS PASSED" if ok else "CHECKS FAILED", flush=True)
        return 0 if ok else 1
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
