# Changelog

## 0.2.0 — 2026-11-10 · Interaction preview

- Shared press/release, selection, menu, tooltip, popover and dialog transitions.
- Oval slider thumbs with bounded follow feedback, coordinated fill and handle,
  direct logical values, keyboard/mirroring support and Reduce Motion.
- Vector Settings icons and window buttons, overlay scrollbars and smooth sidebar
  hover/selection, including spring motion in popup menus.
- Search clearing, empty search results, a keyboard navigation group and neutral
  selection when the Settings window is inactive.
- Anchored contextual help, capsule-shaped history feedback and interruptible
  category transitions that preserve Mouse settings and history.
- Switch feedback with optional on/off symbols via `Theme.differentiateWithoutColor`.
- Motion Lab, instrumented input/frame recording and offline frame inspection.
- New screenshots, videos, release media provenance and portable documentation.

Locally verified with Qt 6.12.0 / NixOS 26.11 / GCC 16 / X11/OpenGL:
140 QML and 6 C++ outcomes, plus native interaction groups. The CI matrix uses
Qt 6.8.2. Native macOS/Windows, Wayland, AppKit parity and a full screen-reader
audit remain unverified for this version. This is a source-only pre-release.

## 0.1.0 — 2026-11-08 · Preview

First source release. Public APIs may change in subsequent `0.x` versions.

- Reusable static `QtMacOS` QML module, shared theme, original window shell,
  explicit buttons, fields, checkboxes, menus, sliders and switches.
- Finder-inspired gallery with light/dark appearance, search, sorting,
  list/grid selection, keyboard navigation and Linux/X11 window controls.
- Mouse settings gallery with independent sliders, switches, popup selection,
  an Advanced dialog and original sidebar icons. Settings are in-memory demos.
- Ten HIG layout families: boxes, collections, columns, disclosure, labels,
  lists/tables, lockups, outlines, split views and tabs. Lockups are explicitly
  a tvOS-inspired adaptation. Views share model state and stable IDs.
- Virtualized collections, sortable tables, hierarchical C++ demo model,
  retained tab contents, resizable splits/columns and keyboard navigation.
- Forty layout reference captures, ten interaction frames, capture manifests
  and reproducible screenshot scripts.
- Tested optional Obsidian integration patches; no change to its generator.
- Human build/integration guide, standalone consumer example, AI instructions,
  MIT license and separate third-party notices.
- CMake/CTest and a GitHub Actions matrix for Linux, Windows and macOS.

Locally verified on Debian 13, GCC 14.2 and Qt 6.8.2. Windows/macOS native
behavior, Wayland behavior, real background blur/vibrancy, full accessibility
auditing and packaged runtime binaries are outside this initial release.
