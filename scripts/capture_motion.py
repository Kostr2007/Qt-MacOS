#!/usr/bin/env python3
"""Capture real Qt interaction frames; optionally encode them with ffmpeg."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

QML = r'''
import QtQuick
import QtQuick.Window
import QtTest
import QtQuick.Controls.Basic as Basic
import QtMacOS

Rectangle {
    id: screen
    width: 680; height: 440
    color: Theme.content
    property string stage: "Ready"
    Text {
        x: 30; y: 26
        text: "Qt-MacOS · Interaction feedback"
        color: Theme.text; font.pixelSize: 22; font.bold: true
    }
    Text { x: 30; y: 65; text: screen.stage; color: Theme.secondary; font.pixelSize: 15 }
    MacPushButton { id: apply; x: 30; y: 120; text: "Apply changes"; highlighted: true }
    MacSwitch { id: toggle; x: 30; y: 200 }
    Text { x: 100; y: 207; text: toggle.checked ? "Enabled" : "Disabled"; color: Theme.text; font.pixelSize: 16 }
    MacSlider { id: slider; x: 30; y: 290; width: 370; value: 0.25; stepSize: 0.05 }
    MacPopupButton { id: popup; x: 380; y: 120; model: ["Studio", "Library", "Archive"] }
    Text { x: 30; y: 392; text: "Actual Qt captures · no generated frames"; color: Theme.secondary; font.pixelSize: 12 }
    MacDialog {
        id: dialog; parent: screen; x: 175; y: 130; width: 340
        title: "Changes applied"
        standardButtons: Basic.Dialog.Ok
        contentItem: MacLabel { text: "Dismiss with Escape. Focus returns to your control."; width: 290 }
    }
    TestCase {
        name: "MotionCapture"
        when: windowShown
        property int frame: 0
        function shot() {
            // Popups are reparented into the window overlay. Capture that too.
            const image = grabImage(screen.Window.window.contentItem)
            verify(image.width > 0)
            image.save(__FRAME_DIR__ + "/frame-" + String(frame++).padStart(4, "0") + ".png")
        }
        function frames(count) {
            for (let i = 0; i < count; ++i) { wait(25); shot() }
        }
        function test_capture() {
            failOnWarning(/.*/)
            Theme.dark = false; Theme.reducedMotion = false
            mouseMove(screen, 650, 410); wait(250)
            screen.stage = "Pointer · press, hold, release"
            frames(12)
            mousePress(apply); frames(8)
            mouseRelease(apply); frames(16)
            screen.stage = "Keyboard · Space uses the same feedback"
            apply.forceActiveFocus(); keyPress(Qt.Key_Space); frames(8)
            keyRelease(Qt.Key_Space); frames(16)
            screen.stage = "Switch · direct input, soft settling"
            mouseClick(toggle); frames(18)
            screen.stage = "Slider · follows your pointer without lag"
            mousePress(slider, 90, 16)
            for (let i = 0; i < 14; ++i) {
                mouseMove(slider, 90 + i * 16, 16); frames(1)
            }
            mouseRelease(slider, 298, 16); frames(12)
            screen.stage = "Popup · short, anchored appearance"
            mouseClick(popup); frames(16)
            keyClick(Qt.Key_Escape); frames(10)
            screen.stage = "Dialog · appear, dismiss, restore focus"
            apply.forceActiveFocus(); dialog.open(); frames(16)
            keyClick(Qt.Key_Escape); frames(12)
            screen.stage = "Reduce Motion · same actions, immediate feedback"
            Theme.reducedMotion = true
            mousePress(apply); frames(6)
            mouseRelease(apply); mouseClick(toggle); frames(16)
            dialog.open(); frames(8)
            keyClick(Qt.Key_Escape); frames(12)
            Theme.reducedMotion = false
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=Path("build/qtmacos-tests"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ffmpeg", type=Path)
    args = parser.parse_args()
    binary = args.binary.resolve()
    args.output.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ-"),
                               dir=args.output.resolve()))
    frames = run / "frames"
    frames.mkdir()
    source = run / "tst_motion_capture.qml"
    source.write_text(QML.replace("__FRAME_DIR__", json.dumps(str(frames))), encoding="utf-8")
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software")
    command = [str(binary), "-input", str(source)]
    result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=60)
    (run / "stdout.txt").write_text(result.stdout)
    (run / "stderr.txt").write_text(result.stderr)
    images = sorted(frames.glob("frame-*.png"))
    manifest = {"command": command, "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
                "returncode": result.returncode, "fps": 40,
                "environment": {k: env[k] for k in ("QT_QPA_PLATFORM", "QT_QUICK_BACKEND", "QML_IMPORT_PATH") if k in env},
                "frames": [{"file": str(p.relative_to(run)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in images]}
    if result.returncode or not images:
        (run / "manifest.json").write_text(json.dumps(manifest, indent=2))
        raise SystemExit(result.stdout + result.stderr)
    if args.ffmpeg:
        encode = [str(args.ffmpeg), "-hide_banner", "-loglevel", "error", "-framerate", "40",
                  "-i", str(frames / "frame-%04d.png"), "-c:v", "libx264", "-crf", "18",
                  "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(run / "motion.mp4")]
        encoded = subprocess.run(encode, capture_output=True, text=True, timeout=60)
        manifest.update(encode_command=encode, encode_returncode=encoded.returncode)
        (run / "encode-stderr.txt").write_text(encoded.stderr)
        (run / "manifest.json").write_text(json.dumps(manifest, indent=2))
        encoded.check_returncode()
    else:
        (run / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(run)


if __name__ == "__main__":
    main()
