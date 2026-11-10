#!/usr/bin/env python3
"""Replay hover/reversal/release, recording actual Qt inputs, pixels and state."""
import argparse
from datetime import datetime, timezone
import hashlib
import html
import json
import os
from pathlib import Path
import subprocess
import tempfile

QML = r'''
import QtQuick
import QtQuick.Window
import QtTest
import QtMacOS

Rectangle {
    id: board
    width: 920; height: 580
    color: Theme.content
    property string stage: "Hover"
    SettingsSidebar {
        id: sidebar; width: 300; height: parent.height
        dark: Theme.dark
        currentKey: "Mouse"
        entries: [{key: "Game Center", icon: "game", tint: "#eeeeef"},
                  {key: "Mouse", icon: "mouse", tint: "#999999"}]
    }
    Text { x: 325; y: 24; text: "Interaction recorder · " + board.stage; color: Theme.text; font.pixelSize: 20 }
    Column {
        x: 330; y: 85; spacing: 32
        Repeater {
            id: sliders
            model: ["Direct", "Elastic shape", "Bounded follow"]
            Column {
                required property string modelData
                required property int index
                width: 550; spacing: 12
                Text { text: modelData; color: Theme.text; font.pixelSize: 16 }
                MacSlider {
                    id: slider; width: parent.width; value: 0.25
                    Component.onCompleted: {
                        if ("motionMode" in slider) slider.motionMode = parent.index;
                    }
                }
            }
        }
    }
    TestCase {
        name: "InteractionReplay"
        when: windowShown
        function at(index) { return sliders.itemAt(index).children[1] }
        function take(tag, profile) {
            const row = findChild(sidebar, "settingsItem_Game Center")
            const probe = row.mapToItem(board.Window.window.contentItem, row.width - 20, row.height / 2)
            const states = []
            for (let i = 0; i < 3; ++i) {
                const s = at(i)
                states.push({profile: i, value: s.value, target: s.visualPosition * (s.availableWidth - s.handle.width),
                             drawn: s.handle.x - s.leftPadding, pressed: s.pressed,
                             offset: "presentationOffset" in s ? s.presentationOffset : 0,
                             stretch: "interactionStretch" in s ? s.interactionStretch : 0})
            }
            verify(interactionRecorder.sample({tag: tag, activeProfile: profile, sliders: states,
                     probe_x: probe.x, probe_y: probe.y, hovered: row.hovered, selected: row.highlighted}))
        }
        function test_replay() {
            failOnWarning(/.*/)
            Theme.dark = __DARK__; Theme.reducedMotion = __REDUCED__
            mouseMove(board, 900, 560); wait(250)
            verify(interactionRecorder.start(__OUTPUT__, board.Window.window, true))
            take("hover-rest", -1)
            const row = findChild(sidebar, "settingsItem_Game Center")
            mouseMove(row, row.width - 20, row.height / 2)
            for (let n = 0; n < 10; ++n) { wait(16); take("hover-enter", -1) }
            mouseMove(board, 900, 560)
            for (let n = 0; n < 10; ++n) { wait(16); take("hover-exit", -1) }
            for (let n = 0; n < 6; ++n) {
                mouseMove(row, row.width - 20, row.height / 2); wait(16); take("hover-interrupt-enter", -1)
                mouseMove(board, 900, 560); wait(16); take("hover-interrupt-exit", -1)
            }
            for (let i = 0; i < 3; ++i) {
                const s = at(i)
                board.stage = ["Direct", "Elastic shape", "Bounded follow"][i]
                mousePress(s, s.handle.x + s.handle.width / 2, 16)
                let releaseX = 0
                for (let n = 0; n < 28; ++n) {
                    const t = n < 9 ? 0.25 + n * 0.065 : n < 18 ? 0.83 - (n - 9) * 0.075 : 0.16 + (n - 18) * 0.057
                    const x = s.handle.width / 2 + t * (s.availableWidth - s.handle.width)
                    releaseX = x
                    mouseMove(s, x, 16); wait(16); take("drag", i)
                }
                // Release at the actual pointer, not at a lagging visual centre.
                mouseRelease(s, releaseX, 16)
                for (let n = 0; n < 18; ++n) { wait(16); take("release", i) }
            }
            verify(interactionRecorder.stop())
        }
    }
}
'''


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--binary", type=Path, default=Path("build/qtmacos-tests"))
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--dark", action="store_true")
    p.add_argument("--reduced-motion", action="store_true")
    p.add_argument("--platform", choices=["offscreen", "xcb"], default="offscreen")
    p.add_argument("--backend", choices=["software", "auto"], default="software")
    p.add_argument("--ffmpeg", type=Path)
    p.add_argument("--scenario", choices=["slider", "navigation", "details", "popup"], default="slider")
    a = p.parse_args()
    a.output.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ-"), dir=a.output.resolve()))
    source = run / "tst_replay.qml"
    qml = QML if a.scenario == "slider" else (Path(__file__).parent / f"fixtures/{a.scenario}.qml").read_text()
    qml = qml.replace("__DEMO__", json.dumps((Path(__file__).resolve().parent.parent / "demo").as_uri()))
    source.write_text(qml.replace("__OUTPUT__", json.dumps(str(run / "recording"))).replace("__DARK__", str(a.dark).lower()).replace("__REDUCED__", str(a.reduced_motion).lower()))
    env = dict(os.environ, QT_QPA_PLATFORM=a.platform)
    env.pop("QT_QUICK_BACKEND", None)
    if a.backend == "software": env["QT_QUICK_BACKEND"] = "software"
    binary = a.binary.resolve()
    binary_digest = hashlib.sha256(binary.read_bytes()).hexdigest()
    command = [str(binary), "-input", str(source)]
    result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=60)
    (run / "stdout.txt").write_text(result.stdout)
    (run / "stderr.txt").write_text(result.stderr)
    binary_changed = binary_digest != hashlib.sha256(binary.read_bytes()).hexdigest()
    manifest = {"command": command, "returncode": result.returncode, "binary_sha256": binary_digest,
                "binary_changed_during_run": binary_changed,
                "dark": a.dark, "reduced_motion": a.reduced_motion, "platform": a.platform, "backend": a.backend, "scenario": a.scenario}
    (run / "manifest.json").write_text(json.dumps(manifest, indent=2))
    if result.returncode: raise SystemExit(result.stdout + result.stderr)
    if binary_changed: raise SystemExit(f"Binary changed during capture; preserve this run for diagnostics and record again: {run}")
    trace = json.loads((run / "recording/trace.json").read_text())
    samples = trace["samples"]
    for s in samples:
        s["sha256"] = hashlib.sha256((run / "recording" / s["file"]).read_bytes()).hexdigest()
    (run / "recording/trace.json").write_text(json.dumps(trace, indent=2))
    if a.ffmpeg:
        lines = []
        for i, s in enumerate(samples):
            duration = (samples[i+1]["sample_ms"] - s["sample_ms"]) / 1000 if i+1 < len(samples) else .08
            lines += [f"file '{s['file']}'", f"duration {max(.001, duration):.6f}"]
        lines.append(f"file '{samples[-1]['file']}'")
        (run / "recording/frames.txt").write_text('\n'.join(lines))
        for name, speed in [("interaction.mp4", 1), ("slow.mp4", 3)]:
            encoded = subprocess.run([str(a.ffmpeg), "-hide_banner", "-loglevel", "error", "-f", "concat", "-safe", "1",
                "-i", "frames.txt", "-vf", f"setpts={speed}*PTS,pad=ceil(iw/2)*2:ceil(ih/2)*2", "-fps_mode", "vfr", "-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(run / name)],
                cwd=run / "recording", capture_output=True, text=True, timeout=60)
            (run / (name + ".stderr.txt")).write_text(encoded.stderr)
            encoded.check_returncode()
    # A portable review page: original frames, trace and timestamp-based videos.
    (run / "index.html").write_text('<!doctype html><meta charset="utf-8"><title>Interaction trace</title><h1>Actual Qt interaction</h1><p>Instrumented capture; not an FPS or display-latency benchmark.</p><video controls width="920" src="interaction.mp4"></video><p><a href="slow.mp4">3× slow motion</a> · <a href="recording/trace.json">Trace</a></p>')
    print(run)


if __name__ == "__main__": main()
