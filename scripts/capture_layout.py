#!/usr/bin/env python3
"""Capture unmodified PNGs from the real Qt layout gallery into a fresh run."""

import argparse
from datetime import datetime, timezone
import hashlib
import html
import json
import os
from pathlib import Path
import shlex
import struct
import subprocess
import sys
import tempfile
import time


PAGES = (
    "boxes", "collections", "columns", "disclosure", "labels", "lists",
    "lockups", "outline", "split", "tabs",
)
VARIANTS = (
    ("light-default", "studio", "default", ()),
    ("dark-default", "studio", "default", ("--dark",)),
    ("light-active", "studio", "active", ()),
    ("narrow-library", "library", "default", ("--narrow",)),
)


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def png_metadata(path):
    """Read dimensions from PNG's required IHDR; Qt generates the image itself."""
    data = path.read_bytes()
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError("Screenshot is not a PNG with an IHDR header")
    width, height = struct.unpack(">II", data[16:24])
    if not width or not height or b"IEND" not in data[-16:]:
        raise ValueError("Screenshot has invalid dimensions or no PNG end marker")
    return {"width": width, "height": height, "bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest()}


def as_text(value):
    return value.decode("utf-8", errors="replace") if isinstance(value, bytes) else value or ""


def capture(binary, run_dir, page, variant, env, timeout):
    name, dataset, state, extra = variant
    target = run_dir / f"{page}-{name}.png"
    command = [str(binary), "--layout", "--presentation", "--page", page, "--dataset", dataset,
               "--state", state, *extra, "--screenshot", str(target)]
    result = {"page": page, "variant": name, "dataset": dataset, "state": state,
              "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
              "command": command, "command_shell": shlex.join(command),
              "file": target.name, "started_at": utc_now(), "success": False,
              "returncode": None, "timed_out": False, "stdout": "", "stderr": ""}
    started = time.monotonic()
    try:
        completed = subprocess.run(command, env=env, capture_output=True,
                                   text=True, errors="replace", timeout=timeout,
                                   check=False)
        result.update(returncode=completed.returncode, stdout=completed.stdout,
                      stderr=completed.stderr)
        if completed.returncode:
            result["error"] = f"Gallery exited with code {completed.returncode}"
        elif not target.is_file():
            result["error"] = "Gallery did not create the requested screenshot"
        else:
            result.update(png_metadata(target))
            result["success"] = True
        if any(marker in completed.stderr for marker in
               ("ReferenceError:", "TypeError:", "Binding loop", "Required property")):
            result.update(success=False, error="QML runtime error in captured diagnostics")
        if hashlib.sha256(binary.read_bytes()).hexdigest() != result["binary_sha256"]:
            result.update(success=False, error="Executable changed during capture")
    except subprocess.TimeoutExpired as error:
        result.update(timed_out=True, stdout=as_text(error.stdout),
                      stderr=as_text(error.stderr), error=f"Timeout after {timeout:g} seconds")
    except (OSError, ValueError) as error:
        result["error"] = str(error)
    result["elapsed_seconds"] = round(time.monotonic() - started, 4)
    # Keep all Qt diagnostics, including startup font warnings. They are evidence,
    # not a reason to silently discard an otherwise valid capture.
    result["diagnostics_present"] = bool(result["stderr"].strip())
    (run_dir / f"{page}-{name}.stdout.txt").write_text(result["stdout"], encoding="utf-8")
    (run_dir / f"{page}-{name}.stderr.txt").write_text(result["stderr"], encoding="utf-8")
    return result


def write_index(run_dir, manifest):
    cards = []
    for item in manifest["captures"]:
        title = html.escape(f"{item['page']} · {item['variant']}")
        file_name = html.escape(item["file"], quote=True)
        if item["success"]:
            visual = f'<a href="{file_name}"><img loading="lazy" src="{file_name}" alt="{title}"></a>'
            info = f"{item['width']} × {item['height']} · {item['bytes']:,} bytes"
        else:
            visual = '<p class="failed">Capture failed</p>'
            info = html.escape(item.get("error", "Unknown capture error"))
        diagnostics = ""
        if item["stderr"]:
            diagnostics = '<details><summary>Qt stderr</summary><pre>' + html.escape(item["stderr"]) + '</pre></details>'
        cards.append(f'<article><h2>{title}</h2>{visual}<p>{info}</p>'
                     f'<p>Exit: {item["returncode"]} · process: {item["elapsed_seconds"]} s</p>'
                     f'<details><summary>Command</summary><pre>{html.escape(item["command_shell"])}</pre></details>'
                     f'{diagnostics}</article>')
    document = '''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>QtMacOS layout captures</title>
<style>
body {font:15px system-ui,sans-serif; margin:24px; background:#f4f4f6; color:#202023}
main {display:grid; grid-template-columns:repeat(auto-fit,minmax(min(100%,440px),1fr)); gap:20px}
article {background:white; border:1px solid #d4d4da; border-radius:10px; padding:16px; min-width:0}
h1 {font-size:26px} h2 {font-size:17px} img {display:block; width:100%; height:auto}
pre {white-space:pre-wrap; overflow-wrap:anywhere; font-size:12px} .failed {color:#b42318}
details {margin:10px 0} a {color:#005bc4}
</style>
<h1>QtMacOS layout gallery</h1>
'''
    document += f'<p>{manifest["successful"]} / {len(manifest["captures"])} captures succeeded. '
    document += f'Created {html.escape(manifest["started_at"])}. <a href="manifest.json">Full manifest</a>.</p>'
    document += '<p>Direct Qt PNGs; click an image for its original size. Process time includes startup and screenshot delay; it is not a frame-time benchmark.</p>'
    document += '<main>' + "\n".join(cards) + '</main></html>\n'
    (run_dir / "index.html").write_text(document, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", "--binarypath", dest="binary", type=Path,
                        default=Path("build/qtmacos-gallery"), help="Gallery executable")
    parser.add_argument("--output", type=Path, default=Path("docs/screenshots/layout"),
                        help="Parent directory; each invocation creates a fresh run directory")
    parser.add_argument("--pages", nargs="+", choices=PAGES, default=list(PAGES))
    parser.add_argument("--timeout", type=float, default=30, help="Seconds per gallery process")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be greater than zero")
    binary = args.binary.expanduser().resolve()
    if not binary.is_file() or not os.access(binary, os.X_OK):
        parser.error(f"Gallery executable is missing or not executable: {binary}")
    args.output.expanduser().mkdir(parents=True, exist_ok=True)
    prefix = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ-")
    run_dir = Path(tempfile.mkdtemp(prefix=prefix, dir=args.output.expanduser().resolve()))
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software")
    manifest = {"schema_version": 1, "started_at": utc_now(), "binary": str(binary),
                "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
                "working_directory": str(Path.cwd()), "timeout_seconds": args.timeout,
                "environment": {key: env[key] for key in (
                    "QT_QPA_PLATFORM", "QT_QUICK_BACKEND", "QT_PLUGIN_PATH",
                    "QML_IMPORT_PATH", "QML2_IMPORT_PATH", "LD_LIBRARY_PATH") if key in env},
                "captures": [], "successful": 0}
    print(f"Capture directory: {run_dir}", flush=True)
    for page in dict.fromkeys(args.pages):
        for variant in VARIANTS:
            result = capture(binary, run_dir, page, variant, env, args.timeout)
            if result["binary_sha256"] != manifest["binary_sha256"]:
                result.update(success=False, error="Executable changed within capture batch")
            manifest["captures"].append(result)
            manifest["successful"] += int(result["success"])
            status = "OK" if result["success"] else "FAILED"
            print(f"{status}: {page}/{variant[0]}" +
                  (" (stderr recorded)" if result["diagnostics_present"] else ""), flush=True)
            # An interrupted batch still leaves an inspectable record of every completed case.
            (run_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    manifest["finished_at"] = utc_now()
    manifest["success"] = manifest["successful"] == len(manifest["captures"])
    (run_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    write_index(run_dir, manifest)
    print(f"Review: {run_dir / 'index.html'}", flush=True)
    return 0 if manifest["success"] else 1


if __name__ == "__main__":
    sys.exit(main())
