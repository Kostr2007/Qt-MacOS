# Validation — 0.2.0

Environment: NixOS 26.11, GCC 16.2, Qt 6.12.0, CMake 4.4.4, i3/X11. Native
interaction recordings use Qt's OpenGL backend; CTest uses offscreen/software.

- Main library/gallery build and standalone `examples/minimal` build pass.
- CTest: both suites pass, 140 QML and 6 C++ outcomes including init/cleanup.
- Native X11 groups were checked during development: NavigationMotion (15),
  HigDetails (11), PopupSelection (6), plus slider/scrollbar interaction groups.
- Published media is captured again from this release candidate with portable
  provenance. See [media gallery](MEDIA_GALLERY.md) and its manifest.
- QML lint completes with four existing warnings about dynamic `pageKey`/`tabData`
  properties in `MacTabView`.

The reviewed source tree was archived with `git archive` and extracted outside
the checkout. A fresh Release configure/build, both CTest suites and the standalone
consumer configure/build all passed from that extracted archive. Local Markdown
links, publication boundaries and credential-pattern scanning passed as well.

Remote results are available in [the build workflow](https://github.com/Kostr2007/Qt-MacOS/actions/workflows/build.yml).
The CI matrix uses Qt 6.8.2 on Ubuntu, Windows and macOS; a successful build does
not establish all native interactions on those systems.

## Known limits

The i3 native-window smoke test has a known maximize-geometry limitation:
the green window action does not meet the smoke test's expected size increase.
The release-candidate smoke run reproduced this limitation and stopped there.
This release does not claim a full window-manager compatibility pass.

Native macOS/Windows interaction, Wayland, real vibrancy/Liquid Glass and a full
screen-reader/high-contrast audit remain unverified. The source archive contains
no Qt SDK, local reference downloads, compiler output or portable runtime binaries.

Original code and media retain the MIT license; third-party material retains
the licenses listed in [THIRD_PARTY_NOTICES](../THIRD_PARTY_NOTICES.md).
