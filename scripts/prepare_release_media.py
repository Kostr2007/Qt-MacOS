#!/usr/bin/env python3
"""Capture real Qt scenes and export a compact, portable release media set."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import time


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=Path("build/qtmacos-gallery"))
    parser.add_argument("--tests", type=Path, default=Path("build/qtmacos-tests"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--recordings", type=Path, required=True)
    parser.add_argument("--ffmpeg", type=Path, required=True)
    parser.add_argument("--platform", default="xcb", choices=["xcb", "offscreen"])
    parser.add_argument("--i3-floating", action="store_true", help="Float only the capture windows in i3 before taking screenshots")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    output = args.output.resolve()
    if output.exists() and any(output.iterdir()):
        raise SystemExit("Choose an empty output directory; existing media is preserved.")
    output.mkdir(parents=True, exist_ok=True)
    args.recordings.mkdir(parents=True, exist_ok=True)
    raw = Path(tempfile.mkdtemp(prefix="release-media-", dir=args.recordings.resolve()))
    env = dict(os.environ, QT_QPA_PLATFORM=args.platform)
    env.pop("QT_QUICK_BACKEND", None)
    manifest = {"schema": 1, "version": "0.2.0", "created_utc": datetime.now(timezone.utc).isoformat(),
                "gallery_sha256": sha(args.binary.resolve()), "recordings": [], "screenshots": []}
    for name, flags in [("settings-light", ["--settings", "--light"]),
                        ("settings-dark", ["--settings", "--dark"]),
                        ("motion-lab", ["--motion-lab", "--light"])]:
        command = [str(args.binary.resolve()), *flags, "--presentation", "--screenshot", str(output / (name + ".png")),
                   "--render-info", str(raw / (name + ".json"))]
        process = subprocess.Popen(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if args.i3_floating:
            if args.platform != "xcb" or not shutil.which("i3-msg") or not shutil.which("xdotool"):
                process.terminate()
                process.communicate(timeout=5)
                raise SystemExit("--i3-floating requires X11, i3-msg and xdotool")
            deadline = time.monotonic() + 5
            while process.poll() is None and time.monotonic() < deadline:
                found = subprocess.run(["xdotool", "search", "--onlyvisible", "--pid", str(process.pid)], capture_output=True, text=True)
                if found.returncode == 0:
                    window = int(found.stdout.splitlines()[-1])
                    size = "1060 850" if name == "motion-lab" else "1048 910"
                    moved = subprocess.run(["i3-msg", f'[id="{window}"] floating enable, border pixel 0, resize set {size}'], capture_output=True, text=True, check=True)
                    if not all(r.get("success") for r in json.loads(moved.stdout)):
                        raise SystemExit("i3 did not apply capture geometry")
                    width, height = map(int, size.split())
                    subprocess.run(["xdotool", "mousemove", "--window", str(window), str(width - 8), str(height - 8)], check=True)
                    break
                time.sleep(0.02)
            else:
                raise SystemExit("Capture window disappeared before i3 geometry was set")
        stdout, stderr = process.communicate(timeout=30)
        result = subprocess.CompletedProcess(command, process.returncode, stdout, stderr)
        (raw / (name + ".stdout.txt")).write_text(result.stdout)
        (raw / (name + ".stderr.txt")).write_text(result.stderr)
        result.check_returncode()
        manifest["screenshots"].append({"file": name + ".png", "arguments": flags + ["--presentation"],
            "renderer": json.loads((raw / (name + ".json")).read_text()), "stderr_empty": not result.stderr})
    runs = {}
    for scenario, mode, flags in [("navigation", "light", []), ("details", "light", []),
                                  ("popup", "light", []), ("popup", "dark", ["--dark"]),
                                  ("popup", "reduced", ["--reduced-motion"])]:
        command = ["python3", str(root / "scripts/record_interactions.py"), "--scenario", scenario,
                   "--binary", str(args.tests.resolve()), "--output", str(raw), "--platform", args.platform,
                   "--backend", "auto", "--ffmpeg", str(args.ffmpeg.resolve()), *flags]
        result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=120)
        if result.returncode:
            raise SystemExit(result.stdout + result.stderr)
        run = Path(result.stdout.strip())
        trace = json.loads((run / "recording/trace.json").read_text())
        source = json.loads((run / "manifest.json").read_text())
        if (run / "stderr.txt").read_text():
            raise SystemExit(f"Inspect capture diagnostics before publishing: {run}")
        key = scenario + "-" + mode
        runs[key] = (run, trace)
        manifest["recordings"].append({"scenario": scenario, "mode": mode,
            "tests_sha256": source["binary_sha256"], "binary_changed_during_run": source["binary_changed_during_run"],
            "scenario_sha256": sha(run / "tst_replay.qml"), "source_video_sha256": sha(run / "interaction.mp4"),
            "qt_version": trace["qt_version"], "platform": trace["platform"], "graphics_api": trace["graphics_api"],
            "dpr": trace["dpr"], "samples": len(trace["samples"]), "input_events": len(trace["input_events"])})
        print(key, flush=True)
    for name, key, tag in [("help", "navigation-light", "help-enter"),
                           ("search", "details-light", "result-focus"),
                           ("inactive", "details-light", "inactive-window"),
                           ("popup", "popup-light", "hover-third"),
                           ("popup-dark", "popup-dark", "hover-third")]:
        run, trace = runs[key]
        sample = [s for s in trace["samples"] if s["tag"] == tag][-1]
        shutil.copy2(run / "recording" / sample["file"], output / (name + ".png"))
        manifest["screenshots"].append({"file": name + ".png", "scenario": key, "tag": tag,
                                        "sample_ms": sample["sample_ms"], "original_frame_sha256": sample["sha256"]})
    for key, name in [("popup-light", "popup-selection.mp4"), ("popup-reduced", "popup-reduced-motion.mp4")]:
        shutil.copy2(runs[key][0] / "interaction.mp4", output / name)
    command = [str(args.ffmpeg.resolve()), "-hide_banner", "-loglevel", "error"]
    for key in ["navigation-light", "details-light", "popup-light"]:
        command += ["-i", str(runs[key][0] / "interaction.mp4")]
    filters = []
    for i in range(3):
        filters.append(f"[{i}:v]scale=1000:600:force_original_aspect_ratio=decrease,pad=1000:600:(ow-iw)/2:(oh-ih)/2,setsar=1[v{i}]")
    filters.append("[v0][v1][v2]concat=n=3:v=1:a=0[out]")
    subprocess.run(command + ["-filter_complex", ";".join(filters), "-map", "[out]", "-fps_mode", "vfr",
        "-c:v", "libx264", "-crf", "24", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        str(output / "interactions.mp4")], check=True, timeout=90)
    subprocess.run([str(args.ffmpeg.resolve()), "-hide_banner", "-loglevel", "error", "-i", str(output / "popup-selection.mp4"),
        "-filter_complex", "fps=12,scale=600:-2:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3",
        "-loop", "0", str(output / "popup-preview.gif")], check=True, timeout=90)
    manifest["assets"] = []
    for path in sorted(output.iterdir()):
        entry = {"file": path.name, "bytes": path.stat().st_size, "sha256": sha(path)}
        if path.suffix == ".png":
            entry["physical_size"] = list(struct.unpack(">II", path.read_bytes()[16:24]))
        manifest["assets"].append(entry)
    manifest["note"] = "Original PNGs. MP4 overview resizes/letterboxes actual timestamped Qt captures; GIF is a sampled preview. Instrumented capture is not a display FPS/latency measurement."
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(output)


if __name__ == "__main__":
    main()
