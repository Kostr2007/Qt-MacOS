# v0.1.0 source release validation

Validated on 2026-11-08 with Debian 13 x86_64, GCC 14.2, CMake 3.31.6,
Qt 6.8.2 and the software Qt Quick renderer.

| Check | Result |
| --- | --- |
| Existing gallery build and CTest | PASS, 2/2 suites |
| Source-only Git tree archive extracted outside the checkout, fresh Release configure/build and CTest | PASS, 2/2 suites |
| QML interaction tests | 74 passed, 0 failed, 0 skipped, including fixture outcomes |
| C++ model tests | 6 passed, 0 failed, including fixture outcomes |
| Standalone consumer (`examples/minimal`) | Fresh Release build PASS; actual X11 launch PASS, clean application diagnostics |
| Local Markdown file/image targets | No missing targets |
| Staged whitespace check | PASS |
| Source payload | Includes source, tests, illustrations, docs and licenses; excludes SDKs and build outputs |

The QAbstractItemModelTester constructor in the local QtTest SDK emits its
previously reproduced `invalid type 4097` warning. Model assertions pass;
this does not occur in gallery captures or the standalone consumer. See
[model and interaction evidence](LAYOUT_IMPLEMENTATION.ru.md).

Historical native X11 window checks, the 40-frame layout capture matrix,
10 action frames and the pinned Obsidian ON/OFF/generation pilot are linked
from [the gallery](LAYOUT_GALLERY.md). They are separate from headless tests.

The GitHub Actions matrix runs on push. Inspect the run at the release commit
for current Linux/Windows/macOS build and test results. These checks do not
certify native window behavior on Windows/macOS, Wayland, screen readers or
compositor-specific effects. This release ships source rather than portable
runtime binaries.

The first CI run passed on Ubuntu but exposed an SDK incompatibility on
`macos-latest`: Qt 6.8.2 links AGL, removed from the macOS 26 SDK. The release
matrix pins `macos-15` and explicitly selects Xcode 16.4 for that Qt version.
The Actions run at the release commit records the subsequent result.
