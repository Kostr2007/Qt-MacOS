#!/usr/bin/env python3
"""Exercise real X11 window management. Requires DISPLAY with a running WM.
Usage: python3 scripts/native_window_smoke.py build/qtmacos-gallery /tmp/result.json
Optional screenshot path is captured with Pillow ImageGrab.
Pass --settings or --layout after the screenshot path to choose the scene.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time


def run(*args):
    return subprocess.check_output(args, text=True, timeout=5).strip()


def wait_for(probe, message, timeout=6):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        value = probe()
        if value:
            return value
        time.sleep(0.08)
    raise AssertionError(message)


def main():
    binary = str(Path(sys.argv[1]).resolve())
    report = Path(sys.argv[2])
    xd = shutil.which("xdotool")
    if not xd or not os.environ.get("DISPLAY"):
        raise RuntimeError("Requires xdotool and DISPLAY with a running window manager")
    env = dict(os.environ, QT_QPA_PLATFORM="xcb", QT_QUICK_BACKEND="software")
    results = {}
    log = report.with_suffix(".log")
    with log.open("w") as output:
        scene_args = sys.argv[4:]
        settings = "--settings" in scene_args
        app = subprocess.Popen([binary] + scene_args, env=env, stdout=output, stderr=subprocess.STDOUT)
        try:
            def find_window():
                p = subprocess.run([xd, "search", "--onlyvisible", "--pid", str(app.pid)],
                                   capture_output=True, text=True, timeout=2)
                return p.stdout.splitlines()[-1] if p.returncode == 0 else None
            wid = wait_for(find_window, "Application window was not shown")
            run(xd, "windowactivate", "--sync", wid)

            def geometry():
                return {k: int(v) for k, v in (line.split("=", 1)
                        for line in run(xd, "getwindowgeometry", "--shell", wid).splitlines())}

            def click(x, y):
                run(xd, "mousemove", "--window", wid, str(x), str(y), "click", "1")

            initial = geometry()
            click(122, 60) if settings else click(107, 57)  # Green traffic light.
            large = wait_for(lambda: (g if (g := geometry())["WIDTH"] > initial["WIDTH"] else None),
                             "Green control did not maximize the window")
            results["maximize"] = large
            click(98, 36) if settings else click(83, 33)  # No shadow inset while maximized.
            wait_for(lambda: geometry()["WIDTH"] == initial["WIDTH"], "Green control did not restore")
            results["restore"] = geometry()

            # Drag empty titlebar space; QWindow.startSystemMove delegates to the WM.
            before = geometry()
            run(xd, "mousemove", "--window", wid, "900" if settings else "450", "55", "mousedown", "1")
            run(xd, "mousemove_relative", "--sync", "70", "40")
            time.sleep(0.12)
            run(xd, "mouseup", "1")
            wait_for(lambda: geometry()["X"] != before["X"] or geometry()["Y"] != before["Y"],
                     "Titlebar drag did not move the window")
            results["drag"] = geometry()

            before = geometry()
            run(xd, "mousemove", "--window", wid, str(before["WIDTH"] - 24),
                str(before["HEIGHT"] - 24), "mousedown", "1")
            run(xd, "mousemove_relative", "--sync", "--", "-70", "-40")
            time.sleep(0.12)
            run(xd, "mouseup", "1")
            wait_for(lambda: geometry()["WIDTH"] < before["WIDTH"], "Resize hit region failed")
            results["resize"] = geometry()
            run(xd, "windowsize", wid, str(initial["WIDTH"]), str(initial["HEIGHT"]))

            click(91, 60) if settings else click(82, 57)  # Yellow traffic light.
            wait_for(lambda: "HIDDEN" in run("xprop", "-id", wid, "_NET_WM_STATE"),
                     "Yellow control did not minimize the window")
            results["minimize"] = True
            run(xd, "windowmap", wid)
            run(xd, "windowactivate", "--sync", wid)
            wait_for(lambda: "HIDDEN" not in run("xprop", "-id", wid, "_NET_WM_STATE"),
                     "Window did not restore after minimizing")
            run(xd, "windowmove", wid, str(initial["X"]), str(initial["Y"]))
            if len(sys.argv) > 3:
                from PIL import ImageGrab
                run(xd, "mousemove", "10", "10")
                time.sleep(0.2)
                ImageGrab.grab(xdisplay=os.environ["DISPLAY"]).save(sys.argv[3])
            click(60, 60) if settings else click(57, 57)  # Red traffic light.
            assert app.wait(timeout=5) == 0, "Closing the window returned a failure"
            results["close"] = True
            results["success"] = True
        except BaseException as error:
            results["success"] = False
            results["error"] = str(error)
            raise
        finally:
            subprocess.run([xd, "mouseup", "1"], timeout=2, check=False)
            if app.poll() is None:
                app.terminate()
                app.wait(timeout=5)
            report.write_text(json.dumps(results, indent=2) + "\n")
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
