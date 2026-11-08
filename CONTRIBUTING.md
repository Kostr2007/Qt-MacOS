# Contributing

Start with [the build guide](docs/GETTING_STARTED.md) and
[the repository instructions](AGENTS.md). Humans and coding agents follow the
same component and evidence contracts.

For a bug, include the OS, Qt version, compiler, renderer, launch command and
expected/actual behavior. A small QML reproduction or an actual screenshot is
especially helpful. Remove personal file paths and secrets before sharing logs.

For a change, describe the user-visible result and any public API changes.
Build the gallery and run CTest. Exercise affected controls with both mouse and
keyboard and in both themes. For model changes, preserve stable selection and
test sorting/filtering/reset behavior. For visual changes, attach before/after
Qt captures at the same size and scale; use the capture script for layout pages.

Keep demo data outside the public module and changes focused. New components
need a gallery example, documented properties/signals, and meaningful behavior
coverage. Public APIs are still evolving in the `0.x` preview series.

Contributions to original library code are under MIT. Contributions to the
Obsidian patch files follow their GPL-2.0-or-later terms. Preserve all asset
notices; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
