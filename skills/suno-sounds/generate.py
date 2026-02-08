#!/usr/bin/env python3
"""Suno API sound & music generator with batch support.

Usage:
    python3 generate.py --prompt "Short referee whistle blast"
    python3 generate.py --definitions sounds.json --priority 1
    python3 generate.py --check-status
    python3 generate.py --definitions sounds.json --list
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError

API_BASE = "https://api.sunoapi.org/api/v1"
USER_AGENT = "SunoSoundGen/1.0"  # Required — default Python UA gets 403'd by Cloudflare
DEFAULT_CALLBACK = "https://localhost/suno-callback"  # Dummy — required by API but unused when polling
OUTPUT_DIR = Path("generated")
STATUS_FILE = Path("generation_status.json")


# ── API ──────────────────────────────────────────────────────────────────────

def api_request(endpoint: str, api_key: str, method: str = "GET", data: dict | None = None) -> dict:
    url = f"{API_BASE}/{endpoint}"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "User-Agent": USER_AGENT,
    }
    body = json.dumps(data).encode() if data else None
    req = Request(url, data=body, headers=headers, method=method)
    try:
        with urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except HTTPError as e:
        error_body = e.read().decode() if e.fp else ""
        print(f"  API {e.code}: {error_body}", file=sys.stderr)
        raise


def submit_generation(prompt: str, api_key: str, *,
                      instrumental: bool = True,
                      custom_mode: bool = False,
                      style: str | None = None,
                      title: str | None = None,
                      callback_url: str = DEFAULT_CALLBACK) -> str | None:
    """Submit a generation request. Returns task ID or None on failure."""
    payload = {
        "prompt": prompt,
        "customMode": custom_mode,
        "instrumental": instrumental,
        "model": "V5",
        "callBackUrl": callback_url,
    }
    if custom_mode:
        payload["style"] = style or "sound effect"
        payload["title"] = title or "generated"

    try:
        result = api_request("generate", api_key, method="POST", data=payload)
        if result.get("code") == 200:
            return result["data"]["taskId"]
        print(f"  Unexpected response: {result}", file=sys.stderr)
    except HTTPError:
        pass
    return None


def poll_task(task_id: str, api_key: str) -> dict:
    """Check task status. Returns full data dict."""
    result = api_request(f"generate/record-info?taskId={task_id}", api_key)
    return result.get("data", {})


def download_file(url: str, dest: Path):
    req = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(req, timeout=60) as resp:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(resp.read())


# ── Auth ─────────────────────────────────────────────────────────────────────

def load_api_key(explicit_key: str | None) -> str:
    """Resolve API key: explicit arg > env var > .env file."""
    if explicit_key:
        return explicit_key

    key = os.environ.get("SUNO_API_KEY")
    if key:
        return key

    env_path = Path(".env")
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line.startswith("SUNO_API_KEY=") and not line.startswith("#"):
                key = line.split("=", 1)[1].strip().strip("'\"")
                if key:
                    return key

    print("Error: No API key found.", file=sys.stderr)
    print("  Set SUNO_API_KEY in .env, environment, or pass --api-key", file=sys.stderr)
    sys.exit(1)


def check_env_gitignored():
    """Warn if .env exists but isn't gitignored."""
    if not Path(".env").exists():
        return
    gitignore = Path(".gitignore")
    if gitignore.exists() and ".env" in gitignore.read_text():
        return
    print("WARNING: .env exists but may not be in .gitignore — risk of committing secrets",
          file=sys.stderr)


# ── Status tracking ──────────────────────────────────────────────────────────

def load_status() -> dict:
    if STATUS_FILE.exists():
        return json.loads(STATUS_FILE.read_text())
    return {"tasks": {}, "completed": []}


def save_status(status: dict):
    STATUS_FILE.write_text(json.dumps(status, indent=2) + "\n")


# ── Commands ─────────────────────────────────────────────────────────────────

def cmd_single(args):
    """Generate a single sound from --prompt."""
    api_key = load_api_key(args.api_key)
    print(f"Submitting: \"{args.prompt[:80]}{'...' if len(args.prompt) > 80 else ''}\"")

    task_id = submit_generation(
        args.prompt, api_key,
        instrumental=not args.vocals,
        custom_mode=bool(args.style),
        style=args.style,
        title=args.title,
    )
    if not task_id:
        print("Generation failed.", file=sys.stderr)
        sys.exit(1)

    print(f"Task ID: {task_id}")

    status = load_status()
    label = args.title or "single"
    status["tasks"][label] = {
        "task_id": task_id,
        "status": "PENDING",
        "submitted_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
    }
    save_status(status)
    print(f"Run --check-status in ~2 minutes to download results.")


def cmd_batch(args):
    """Generate sounds from a definitions file."""
    api_key = load_api_key(args.api_key)
    defs = json.loads(Path(args.definitions).read_text())
    sounds = defs.get("sounds", [])

    # Filter
    if args.priority is not None:
        sounds = [s for s in sounds if s["priority"] <= args.priority]
    if args.sound:
        sounds = [s for s in sounds if s["id"] == args.sound]
    if args.category:
        sounds = [s for s in sounds if s["category"] == args.category]

    if not sounds:
        print("No sounds match filters.")
        return

    status = load_status()
    done = set(status.get("completed", []))
    pending = [s for s in sounds if s["id"] not in done]

    if args.list:
        _print_list(sounds, done)
        return

    if not pending:
        print("All matching sounds already generated.")
        return

    print(f"Sounds to generate: {len(pending)} (of {len(sounds)} matched, {len(done)} already done)")

    if args.dry_run:
        for s in pending:
            print(f"  [{s['priority']}] {s['id']:20s} {s['type']:8s} {s['category']}")
        return

    for i, sound in enumerate(pending):
        print(f"[{i+1}/{len(pending)}] {sound['id']}")
        task_id = submit_generation(sound["prompt"], api_key)
        if task_id:
            print(f"  Task: {task_id}")
            status["tasks"][sound["id"]] = {
                "task_id": task_id,
                "status": "PENDING",
                "submitted_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
            }
            save_status(status)
        else:
            print(f"  FAILED to submit")

        if i < len(pending) - 1:
            time.sleep(5)

    print(f"\nSubmitted {len(pending)} sounds. Run --check-status in ~2 minutes.")


def cmd_check_status(args):
    """Poll pending tasks and download completed audio."""
    api_key = load_api_key(args.api_key)
    status = load_status()
    tasks = status.get("tasks", {})

    if not tasks:
        print("No pending tasks.")
        return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    completed = 0
    pending = 0

    for sound_id, info in list(tasks.items()):
        if info.get("status") == "DOWNLOADED":
            continue

        task_id = info["task_id"]
        print(f"  {sound_id}: ", end="", flush=True)

        try:
            result = poll_task(task_id, api_key)
        except HTTPError:
            print("ERROR (API call failed)")
            pending += 1
            continue

        task_status = result.get("status", "UNKNOWN")
        print(task_status)

        if task_status == "SUCCESS":
            audio_list = result.get("response", {}).get("sunoData", [])
            for j, audio in enumerate(audio_list):
                url = audio.get("sourceAudioUrl") or audio.get("audioUrl") or ""
                if not url:
                    continue
                suffix = f"_v{j+1}" if len(audio_list) > 1 else ""
                dest = OUTPUT_DIR / f"{sound_id}{suffix}.mp3"
                dur = audio.get("duration", "?")
                print(f"    v{j+1}: {dur}s → {dest}")
                try:
                    download_file(url, dest)
                except Exception as e:
                    print(f"    Download failed: {e}", file=sys.stderr)

            info["status"] = "DOWNLOADED"
            status.setdefault("completed", []).append(sound_id)
            completed += 1

        elif task_status in ("PENDING", "GENERATING", "TEXT_SUCCESS"):
            pending += 1
            if task_status == "TEXT_SUCCESS":
                print(f"    Audio rendering — retry in ~90s")

        elif task_status == "FAILED":
            info["status"] = "FAILED"
            print(f"    Re-submit this sound to retry")

        save_status(status)
        time.sleep(1)

    print(f"\nDownloaded: {completed}  |  Pending: {pending}  |  Total done: {len(status.get('completed', []))}")
    if pending:
        print("Re-run --check-status to poll remaining tasks.")


def _print_list(sounds: list[dict], done: set[str]):
    by_cat = {}
    for s in sounds:
        by_cat.setdefault(s["category"], []).append(s)

    for cat, items in sorted(by_cat.items()):
        print(f"\n  {cat.upper()}")
        for s in items:
            mark = "done" if s["id"] in done else "    "
            print(f"    [{s['priority']}] {mark} {s['id']:20s} {s['type']:8s} {s.get('filename', '')}")


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(description="Suno sound & music generator")

    # Auth
    p.add_argument("--api-key", help="Suno API key (or use SUNO_API_KEY env / .env file)")

    # Modes
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--prompt", help="Generate a single sound from a text prompt")
    mode.add_argument("--definitions", metavar="FILE", help="Batch generate from a JSON definitions file")
    mode.add_argument("--check-status", action="store_true", help="Poll pending tasks and download results")

    # Single mode options
    p.add_argument("--style", help="Style tag for custom mode")
    p.add_argument("--title", help="Title for custom mode")
    p.add_argument("--vocals", action="store_true", help="Include vocals (default: instrumental only)")

    # Batch mode options
    p.add_argument("--priority", type=int, help="Generate sounds with priority <= N")
    p.add_argument("--sound", help="Generate a specific sound by ID")
    p.add_argument("--category", help="Generate sounds in a specific category")
    p.add_argument("--dry-run", action="store_true", help="Preview without API calls")
    p.add_argument("--list", action="store_true", help="List sounds and their status")

    args = p.parse_args()

    check_env_gitignored()

    if args.check_status:
        cmd_check_status(args)
    elif args.prompt:
        cmd_single(args)
    elif args.definitions:
        cmd_batch(args)
    else:
        p.print_help()


if __name__ == "__main__":
    main()
