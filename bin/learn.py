#!/usr/bin/env python3
"""Local learner CLI for a MATLAB learning harness."""
from __future__ import annotations
import argparse
import json
import os
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "curriculum" / "modules.json"
STATE_DIR = ROOT / ".learning"
STATE_FILE = STATE_DIR / "progress.json"


def empty_state():
    return {"current": None, "completed": {}, "notes": {}}


def load_manifest():
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def load_state():
    if not STATE_FILE.exists():
        return empty_state()
    try:
        state = json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SystemExit(
            f"Learner state is unreadable or malformed at {STATE_FILE}. "
            "Repair or move that file aside; no learner data was changed."
        ) from error
    if not isinstance(state, dict):
        raise SystemExit("Learner state must be a JSON object; no learner data was changed.")
    state.setdefault("current", None)
    state.setdefault("completed", {})
    state.setdefault("notes", {})
    if state["current"] is not None and not isinstance(state["current"], str):
        raise SystemExit("Learner state field 'current' must be text or null; no data was changed.")
    if not isinstance(state["completed"], dict) or not all(
        isinstance(key, str) and isinstance(value, bool)
        for key, value in state["completed"].items()
    ):
        raise SystemExit(
            "Learner state field 'completed' must map module IDs to booleans; "
            "no data was changed."
        )
    if not isinstance(state["notes"], dict) or not all(
        isinstance(key, str) and isinstance(value, str) for key, value in state["notes"].items()
    ):
        raise SystemExit(
            "Learner state field 'notes' must map module IDs to text; no data was changed."
        )
    return state


def save_state(state):
    payload = json.dumps(state, indent=2) + "\n"
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{STATE_FILE.name}.", suffix=".tmp", dir=STATE_DIR
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary_name, STATE_FILE)
    except BaseException:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def resolve_module(manifest, ref):
    modules = manifest["modules"]
    if ref is None:
        state = load_state()
        if state.get("current"):
            ref = state["current"]
        else:
            ref = next(
                (m["id"] for m in modules if m["status"] == "implemented"),
                modules[0]["id"],
            )
    ref_text = str(ref).strip().upper()
    for module in modules:
        candidates = {
            module["id"],
            str(module["number"]),
            f"{module['number']:02d}",
            module["slug"].upper(),
        }
        if ref_text in candidates:
            return module
    raise SystemExit(f"Unknown module: {ref}")


def print_start(module):
    folder = ROOT / module["folder"]
    print(f"{module['id']} — {module['title']}")
    print(f"Status: {module['status']}")
    print(f"Guiding question: {module['guiding_question']}")
    print(f"Folder: {folder.relative_to(ROOT)}")
    if module["status"] != "implemented":
        print(
            "This module is scaffolded. Activate its governed implementation batch "
            "before tutor use."
        )
        return 2
    print("\nMATLAB:")
    print(f"  launch_lesson('{module['id']}')")
    print("\nTutor files:")
    for name in ["README.md", "lesson.md", "walkthrough.md", "checks.md"]:
        path = folder / name
        if path.exists():
            print(f"  {path.relative_to(ROOT)}")
    return 0


def missing_prerequisites(module, state):
    completed = state.get("completed", {})
    return [
        prerequisite
        for prerequisite in module.get("prerequisites", [])
        if completed.get(prerequisite) is not True
    ]


def print_prerequisite_refusal(module, missing):
    print(
        f"{module['id']} is locked. Complete prerequisite(s): "
        f"{', '.join(missing)}."
    )
    print("Learner progress was not changed.")
    return 2


def cmd_start(args):
    manifest = load_manifest()
    module = resolve_module(manifest, args.module)
    if module["status"] != "implemented":
        return print_start(module)
    state = load_state()
    missing = missing_prerequisites(module, state)
    if missing:
        return print_prerequisite_refusal(module, missing)
    state["current"] = module["id"]
    save_state(state)
    return print_start(module)


def cmd_continue(_args):
    manifest = load_manifest()
    state = load_state()
    module = resolve_module(manifest, state.get("current"))
    missing = missing_prerequisites(module, state)
    if missing:
        return print_prerequisite_refusal(module, missing)
    return print_start(module)


def cmd_list(_args):
    manifest = load_manifest()
    state = load_state()
    completed = state.get("completed", {})
    for m in manifest["modules"]:
        marker = (
            "✓"
            if completed.get(m["id"])
            else ("●" if m["status"] == "implemented" else "○")
        )
        print(f"{marker} {m['id']}  Phase {m['phase']}  {m['title']} [{m['status']}]")
    return 0


def cmd_status(_args):
    manifest = load_manifest()
    state = load_state()
    completed = state.get("completed", {})
    complete = sum(bool(completed.get(module["id"])) for module in manifest["modules"])
    implemented = sum(m["status"] == "implemented" for m in manifest["modules"])
    print(f"Track: {manifest['title']}")
    print(
        f"Modules: {manifest['module_count']} total, {implemented} implemented, "
        f"{complete} completed"
    )
    print(f"Current: {state.get('current') or 'none'}")
    return 0


def cmd_complete(args):
    manifest = load_manifest()
    module = resolve_module(manifest, args.module)
    if module["status"] != "implemented":
        raise SystemExit("Cannot complete a scaffolded module.")
    state = load_state()
    missing = missing_prerequisites(module, state)
    if missing:
        return print_prerequisite_refusal(module, missing)
    if not args.checks_passed:
        print(
            f"Completion not recorded. First run: run_module_checks('{module['id']}')"
        )
        print("Then rerun with --checks-passed and a short --teach-back.")
        return 2
    teach_back = args.teach_back.strip()
    if not teach_back:
        print("Completion not recorded. Provide a short mechanism-first --teach-back.")
        return 2
    state.setdefault("completed", {})[module["id"]] = True
    completion_note = f"Teach-back: {teach_back}"
    if args.note.strip():
        completion_note += f"\nNote: {args.note.strip()}"
    state.setdefault("notes", {})[module["id"]] = completion_note
    state["current"] = module["id"]
    save_state(state)
    print(f"Marked {module['id']} complete after check confirmation and teach-back.")
    return 0


def cmd_check(args):
    manifest = load_manifest()
    module = resolve_module(manifest, args.module)
    folder = ROOT / module["folder"]
    if not (folder / "run_checks.m").exists():
        raise SystemExit(f"{module['id']} has no executable checks.")
    print(f"Run in MATLAB: run_module_checks('{module['id']}')")
    return 0


def main():
    parser = argparse.ArgumentParser(prog="learn")
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("start")
    p.add_argument("module", nargs="?")
    p.set_defaults(func=cmd_start)
    p = sub.add_parser("continue")
    p.set_defaults(func=cmd_continue)
    p = sub.add_parser("list")
    p.set_defaults(func=cmd_list)
    p = sub.add_parser("status")
    p.set_defaults(func=cmd_status)
    p = sub.add_parser("complete")
    p.add_argument("module")
    p.add_argument("--checks-passed", action="store_true")
    p.add_argument("--teach-back", default="")
    p.add_argument("--note", default="")
    p.set_defaults(func=cmd_complete)
    p = sub.add_parser("check")
    p.add_argument("module", nargs="?")
    p.set_defaults(func=cmd_check)
    args = parser.parse_args()
    raise SystemExit(args.func(args))


if __name__ == "__main__":
    main()
