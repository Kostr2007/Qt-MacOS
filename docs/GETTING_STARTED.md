# Build, explore and integrate Qt-MacOS

[Русская инструкция](../README.ru.md) · [AI repository instructions](../AGENTS.md)

## Prerequisites

- CMake 3.21 or later, a C++17 compiler, and Ninja or the native build tool.
- Qt 6 with Quick, Quick Controls 2, the QML runtime modules and SVG image
  support. Quick Test and Qt Test are required for the default test build.
- Python 3 only if you want to use the screenshot automation scripts.

Qt 6.8.2 is the development/test version. CMake declares Qt 6.4 as the minimum;
that minimum has not yet been verified separately. Use one matching Qt kit and
compiler (MSVC with MSVC Qt on Windows, for example). Do not mix libraries from
different Qt versions. The Qt installer can add the desktop kit and its modules.

On Debian/Ubuntu, the package set typically includes:

```sh
sudo apt install build-essential cmake ninja-build qt6-base-dev \
  qt6-declarative-dev qt6-svg-plugins qml6-module-qtquick \
  qml6-module-qtquick-window qml6-module-qtquick-controls \
  qml6-module-qtquick-layouts qml6-module-qtquick-templates \
  qml6-module-qtqml-workerscript qml6-module-qt-labs-qmlmodels \
  qml6-module-qttest
```

Package names/Qt versions vary by distribution. If your distribution is older
than Qt 6.4, use a newer Qt kit. A compositor is needed to display the outer
window transparency and shadow as intended under X11. Offscreen mode does not
need a desktop session.

## Build the gallery and tests

From the repository root:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --parallel 4
ctest --test-dir build -C Release --output-on-failure --no-tests=error
```

If Qt is not on CMake's search path, add
`-DCMAKE_PREFIX_PATH=/path/to/Qt/6.8.2/gcc_64` (or your actual kit) to configure.
Choose another build directory when switching kits or generators.

For a single-config generator the executable is `build/qtmacos-gallery`.
For a multi-config generator use `build/Release/qtmacos-gallery.exe` on Windows
or the corresponding executable path on your platform. Run in a shell that
can locate your Qt runtime libraries/plugins.

## Explore the three scenes

```sh
./build/qtmacos-gallery
./build/qtmacos-gallery --light --grid
./build/qtmacos-gallery --settings
./build/qtmacos-gallery --settings --dark
./build/qtmacos-gallery --layout --page columns
./build/qtmacos-gallery --layout --page tabs --dataset library --narrow
```

| Scene | Useful interactions |
| --- | --- |
| Finder | Ctrl+F search, Escape to close search, column-header sorting, list/grid buttons, keyboard selection, Ctrl+Shift+L theme toggle |
| Mouse settings | Three independent sliders, switch, secondary-click popup, Advanced dialog and Help; values are demo state only |
| Layout | Sidebar pages, shared selection, filtering, add/rename, datasets, tree/column navigation, splits and retained tabs |

Layout page names: `boxes`, `collections`, `columns`, `disclosure`, `labels`,
`lists`, `lockups`, `outline`, `split`, `tabs`. Layout accepts `--dark`,
`--dataset studio|library`, `--state default|active`, `--narrow` and
`--presentation`. Finder starts dark; Mouse settings and Layout start light.

On the custom gallery frame, drag free toolbar space, resize at the edges,
and use the red/yellow/green buttons for close/minimize/maximize. These actions
have been checked under Linux/X11 with Openbox and a compositor. Other window
systems need separate native verification.

## Integrate with an application

Start with the runnable [minimal example](../examples/minimal):

```sh
cmake -S examples/minimal -B build-example -DCMAKE_BUILD_TYPE=Release
cmake --build build-example --config Release --parallel 4
./build-example/qtmacos-example
```

To add Qt-MacOS to your own CMake project, pin a release/commit of this source
tree, then use the same approach as `examples/minimal/CMakeLists.txt`:

```cmake
set(QTMACOS_BUILD_GALLERY OFF CACHE BOOL "" FORCE)
set(QTMACOS_BUILD_TESTS OFF CACHE BOOL "" FORCE)
add_subdirectory(path/to/Qt-MacOS qtmacos)
target_link_libraries(your-app PRIVATE qtmacosplugin Qt6::Quick Qt6::QuickControls2)
```

The path is illustrative; point it at the checked-out dependency. Register the
static plugin in your C++ entry point:

```cpp
#include <QtQml/QQmlExtensionPlugin>
Q_IMPORT_QML_PLUGIN(QtMacOSPlugin)
```

Select `QQuickStyle::setStyle("Basic")` before loading QML. For the custom
`MacWindow`, call `QQuickWindow::setDefaultAlphaBuffer(true)` before creating
windows. Import `QtMacOS` in QML. Controls work in a regular `ApplicationWindow`,
as the example shows, or you can opt into `MacWindow` and its shell. The font is
embedded in the module; `MacWindow` loads it automatically.

Use `Theme.dark` to switch appearance in an engine. Layout view role and adapter
contracts are documented in [LAYOUT_IMPLEMENTATION.ru.md](LAYOUT_IMPLEMENTATION.ru.md).
Your app owns the data and actions. Only the gallery needs `QtMacOS.Demo`.
The current distribution uses `add_subdirectory`; there is no installed
`find_package(QtMacOS)` package yet.

## Capture real illustrations

For a single scene, this saves a PNG and exits (nonzero on failure):

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  ./build/qtmacos-gallery --layout --page columns --presentation \
  --screenshot /tmp/qtmacos-columns.png
```

In PowerShell set the variables first with
`$env:QT_QPA_PLATFORM='offscreen'` and `$env:QT_QUICK_BACKEND='software'`.
Use a writable output path. To capture all ten families in four variants, with
manifests and a local HTML index:

```sh
python3 scripts/capture_layout.py --binary build/qtmacos-gallery \
  --output docs/screenshots/layout --timeout 30
```

The script uses only Python's standard library. `--presentation` provides a
fixed comparison background; it is not a live desktop blur. The checked-in
[gallery](LAYOUT_GALLERY.md) also includes frames from actual interaction tests.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| CMake cannot find Qt6 | Set `CMAKE_PREFIX_PATH` to the matching kit |
| QML module missing | Install its runtime QML module and use the same Qt kit at build and launch |
| SVG unsupported | Install the SVG image plugin (`qt6-svg-plugins` on Debian), check plugin paths |
| Platform plugin cannot load | Check desktop dependencies; use `offscreen` for headless captures only |
| Failure after switching compilers | Configure a fresh directory with a matching Qt kit |
| Opaque/shadowless outer window | Check compositor/alpha support; native window systems differ |

Local validation used Debian 13, GCC 14.2, CMake 3.31.6 and Qt 6.8.2. The local
QtTest model tester emits an `invalid type 4097` warning in its constructor;
it was reproduced outside this project with a minimal model. Model assertions
pass; final gallery captures have clean diagnostics. See
[detailed evidence](LAYOUT_IMPLEMENTATION.ru.md) and Actions for each check's limits.
