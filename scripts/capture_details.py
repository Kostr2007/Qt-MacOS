#!/usr/bin/env python3
"""Capture actual small controls at multiple DPI scales, including overlay states."""
import argparse
from datetime import datetime, timezone
import hashlib
import html
import json
import os
from pathlib import Path
import struct
import subprocess
import tempfile

QML = r'''
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Basic
import QtTest
import QtMacOS

Rectangle {
    id: board
    width: 900; height: 610
    color: Theme.content
    Text { x: 24; y: 18; text: "Actual Qt controls · DPR " + Screen.devicePixelRatio; color: Theme.text; font.pixelSize: 20 }
    Row {
        x: 24; y: 65; spacing: 20
        Repeater {
            model: ["notification", "internet", "privacy", "sound", "focus", "mouse", "keyboard", "cloud"]
            Column {
                required property string modelData
                spacing: 10
                Rectangle {
                    width: 76; height: 76; radius: 16; antialiasing: true; color: "#1685dd"
                    SettingsIcon { anchors.fill: parent; name: modelData }
                }
                Rectangle {
                    width: 28; height: 28; radius: 6; antialiasing: true; color: "#1685dd"
                    SettingsIcon { anchors.fill: parent; name: modelData }
                }
                Text { text: modelData; color: Theme.secondary; font.pixelSize: 11 }
            }
        }
    }
    WindowButtons { id: lights; x: 24; y: 240; windowActive: true; dark: Theme.dark }
    MacSlider { id: slider; x: 24; y: 300; width: 350; value: 0.45 }
    MacSlider { x: 24; y: 390; width: 350; value: 0.75; LayoutMirroring.enabled: true }
    Flickable {
        id: viewport
        x: 520; y: 245; width: 330; height: 320
        contentWidth: width; contentHeight: 1100; clip: true
        Rectangle { width: viewport.width; height: viewport.contentHeight; color: Theme.sidebar }
        Column {
            spacing: 14; x: 16; y: 16
            Repeater {
                model: 25
                Text { required property int index; text: "Sidebar entry " + (index + 1); color: Theme.text; font.pixelSize: 16 }
            }
        }
        Basic.ScrollBar.vertical: MacScrollBar { id: scroll }
    }
    TestCase {
        name: "DetailsCapture"
        when: windowShown
        function capture(name) {
            const image = grabImage(board.Window.window.contentItem)
            verify(image.width > 0)
            image.save(__OUTPUT__ + "/" + name + ".png")
        }
        function test_states() {
            failOnWarning(/.*/)
            Theme.dark = __DARK__
            Theme.reducedMotion = false
            mouseMove(board, 440, 560)
            wait(1400); capture("idle")
            mouseMove(lights, 7, 7); wait(200); capture("window-hover")
            mouseMove(board, 440, 560)
            mousePress(slider, 165, 16); capture("slider-held")
            for (let i = 0; i < 15; ++i) { mouseMove(slider, 165 + i * 8, 16); wait(16) }
            capture("slider-drag")
            mouseRelease(slider, 277, 16)
            viewport.contentY = 260; scroll.active = true
            wait(100); capture("scroll-active")
            scroll.active = false
            mouseMove(scroll, scroll.width / 2, scroll.height / 2)
            wait(180); capture("scroll-hover")
            mouseMove(board, 440, 560)
            wait(1400); capture("scroll-idle")
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=Path("build/qtmacos-tests"))
    parser.add_argument("--gallery", type=Path, help="Gallery binary for physical-pixel DPI captures (auto-detected beside tests)")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--scales", type=float, nargs="+", default=[1, 1.25, 2])
    parser.add_argument("--dark", action="store_true")
    parser.add_argument("--platform", choices=["offscreen", "xcb"], default="offscreen")
    parser.add_argument("--backend", choices=["software", "auto"], default="software")
    args = parser.parse_args()
    if any(scale <= 0 for scale in args.scales):
        parser.error("Scale factors must be positive")
    args.output.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ-"), dir=args.output.resolve()))
    binary = args.binary.resolve()
    gallery = args.gallery.resolve() if args.gallery else binary.parent / "qtmacos-gallery"
    manifest = {"binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
                "platform": args.platform, "backend_requested": args.backend, "runs": []}
    for scale in args.scales:
        dest = run / f"scale-{scale:g}"
        dest.mkdir()
        source = dest / "tst_capture.qml"
        source.write_text(QML.replace("__OUTPUT__", json.dumps(str(dest))).replace("__DARK__", str(args.dark).lower()))
        env = dict(os.environ, QT_QPA_PLATFORM=args.platform, QT_SCALE_FACTOR=str(scale))
        env.pop("QT_QUICK_BACKEND", None)
        if args.backend == "software":
            env["QT_QUICK_BACKEND"] = "software"
        command = [str(binary), "-input", str(source)]
        result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=30)
        (dest / "stdout.txt").write_text(result.stdout)
        (dest / "stderr.txt").write_text(result.stderr)
        captures = []
        for path in sorted(dest.glob("*.png")):
            data = path.read_bytes()
            captures.append({"file": str(path.relative_to(run)), "size": struct.unpack(">II", data[16:24]), "sha256": hashlib.sha256(data).hexdigest()})
        manifest["runs"].append({"scale": scale, "command": command, "returncode": result.returncode, "captures": captures})
        (run / "manifest.json").write_text(json.dumps(manifest, indent=2))
        if result.returncode or len(captures) != 7:
            raise SystemExit(result.stdout + result.stderr)
        # QtTest grabImage normalizes images to logical pixels. Also retain the
        # window's physical pixels, otherwise a 2x check could hide raster defects.
        if gallery.is_file():
            target = dest / "settings-physical.png"
            gallery_command = [str(gallery), "--settings", "--presentation", "--screenshot", str(target)]
            if args.dark:
                gallery_command.append("--dark")
            rendered = subprocess.run(gallery_command, env=env, capture_output=True, text=True, timeout=20)
            (dest / "gallery.stdout.txt").write_text(rendered.stdout)
            (dest / "gallery.stderr.txt").write_text(rendered.stderr)
            if rendered.returncode or not target.is_file():
                raise SystemExit(rendered.stdout + rendered.stderr or "Missing gallery capture")
            data = target.read_bytes()
            entry = manifest["runs"][-1]
            entry["gallery_command"] = gallery_command
            entry["gallery_binary_sha256"] = hashlib.sha256(gallery.read_bytes()).hexdigest()
            entry["captures"].append({"file": str(target.relative_to(run)), "physical_pixels": True,
                                      "size": struct.unpack(">II", data[16:24]), "sha256": hashlib.sha256(data).hexdigest()})
            (run / "manifest.json").write_text(json.dumps(manifest, indent=2))
    cards = []
    for entry in manifest["runs"]:
        for shot in entry["captures"]:
            name = html.escape(shot["file"])
            cards.append(f'<article><p>{name} · {shot["size"]}</p><a href="{name}"><img src="{name}" style="max-width:900px;width:100%"></a></article>')
    (run / "index.html").write_text('<!doctype html><meta charset="utf-8"><title>Actual Qt detail captures</title><h1>Actual Qt controls</h1><p>Test boards use logical pixels. settings-physical.png retains the actual window DPI.</p>' + ''.join(cards))
    print(run)


if __name__ == "__main__":
    main()
