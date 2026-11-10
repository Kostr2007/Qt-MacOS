#!/usr/bin/env python3
"""Compare real gallery rendering backends; retain diagnostics, PNGs and hashes."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=Path("build/qtmacos-gallery"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--platform", choices=["xcb", "offscreen"], default="xcb")
    parser.add_argument("--backends", choices=["auto", "software"], nargs="+", default=["auto", "software"])
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ-"), dir=args.output.resolve()))
    binary = args.binary.resolve()
    manifest = {"binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(), "probes": []}
    for backend in args.backends:
        env = dict(os.environ, QT_QPA_PLATFORM=args.platform, QSG_INFO="1")
        env.pop("QT_QUICK_BACKEND", None)
        if backend == "software":
            env["QT_QUICK_BACKEND"] = "software"
        path = run / f"{backend}.png"
        info = run / f"{backend}.renderer.json"
        command = [str(binary), "--settings", "--presentation", "--screenshot", str(path), "--render-info", str(info)]
        started = time.monotonic()
        try:
            result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=20)
            record = {"backend_requested": backend, "platform": args.platform, "command": command,
                      "elapsed_including_startup": round(time.monotonic() - started, 3),
                      "returncode": result.returncode}
            (run / f"{backend}.stdout.txt").write_text(result.stdout)
            (run / f"{backend}.stderr.txt").write_text(result.stderr)
            if info.is_file():
                record["actual_renderer"] = json.loads(info.read_text())
            if path.is_file():
                data = path.read_bytes()
                record.update(png_size=struct.unpack(">II", data[16:24]), sha256=hashlib.sha256(data).hexdigest())
        except subprocess.TimeoutExpired:
            record = {"backend_requested": backend, "timed_out": True}
        manifest["probes"].append(record)
        (run / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(run)
    if any(p.get("returncode") != 0 or "sha256" not in p for p in manifest["probes"]):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
