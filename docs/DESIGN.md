# Design specification — prototype 0.1

The first profile follows the supplied traditional Finder screenshots: a quiet
sidebar, toolbar, content list/grid, compact controls, and light/dark palettes.
It does not implement or claim the current Apple Liquid Glass appearance.

## Theme API

`Theme` is a QML singleton. `dark` (default `true`), `radius` (6 logical pixels),
and `rowHeight` (32 logical pixels) are mutable properties. Colors update when
`dark` changes and are read-only semantic tokens:

| Token | Dark | Light | Purpose |
| --- | --- | --- | --- |
| window | #292a2d | #f5f5f5 | Window background |
| sidebar | #36373a | #e9e9ec | Navigation surface |
| toolbar | #303135 | #f4f4f5 | Toolbar/footer |
| content | #242528 | #ffffff | Content area |
| text | #f0f0f2 | #252529 | Main foreground |
| secondary | #afb0b8 | #62636b | Supporting text |
| border | #47484d | #d4d4d8 | Surface separators |
| hover | #303136 | #f0f0f2 | Hover/alternating rows |
| selection | #425a79 | #d1e4fc | Selected rows/items |
| accent | #6cb7ff | #0068cf | Focus and accent |
| accentText | #142338 | #ffffff | Text on accent buttons |
| field | #242529 | #ffffff | Input surface |
| button | #47484d | #ffffff | Button surface |

These are project choices, not extracted Apple measurements. Active/inactive
window palettes, high-contrast themes, native materials, system-theme following,
and measured contrast regression checks remain future work. The gallery's theme
switch is a component-development tool, not a recommendation for application UX.

## Icons

The ready-made SVG set comes from **Phosphor Icons core**, regular weight, MIT
licensed, pinned to commit `2b75f3ad12b420c9504ef05df8d2564a28f8500e`.
`assets/icons/LICENSE` contains the complete license. `manifest.json` records
upstream filenames, SHA-256 hashes, and modifications. `search.svg` is an exact
copy of upstream `magnifying-glass.svg` under a semantic local name.

Original SVGs use `currentColor`; public Qt Quick Controls `icon.source` plus
`icon.color` supplies the themed color. Plain `Image` does not inherit that
control tint. For that case `folder-blue.svg` and `file-blue.svg` replace
`currentColor` with `#55b6f8`; the modifications are explicitly recorded.
No Finder assets, SF Symbols, Apple logos, or Apple font files are bundled.

## Verified Apple references

Read on 7 November 2026 from Apple's official DocC JSON endpoints, not merely
inferred from page titles:

- [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars):
  leading navigation between top-level areas; grouping and familiar symbols.
  Current guidance discusses Liquid Glass, beyond this prototype's scope.
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars):
  access to common commands, navigation and search; deliberate item selection
  and logical grouping to avoid overcrowding.
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials):
  separate functional and content layers; materials establish hierarchy. A
  translucent rectangle is not equivalent to native system blur.
- [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode):
  respect system appearance in a finished app and test both modes, including
  Increase Contrast and Reduce Transparency. The gallery's manual switch is
  deliberately only a development aid.

Retrieved JSON URLs follow
`https://developer.apple.com/tutorials/data/design/human-interface-guidelines/<slug>.json`.
Earlier planning noted a proxy block; access now succeeds. The current documents
include newer design generations, so they must not be used to label a traditional
Finder screenshot replica as the latest macOS UI.

## Validation targets

Check normal, hover, pressed, disabled, focus and selection states; Cyrillic and
long labels; logical scaling at 100/125/150/200%; list/grid navigation with keyboard;
and theme changes while controls are visible. Aim for 4.5:1 normal text contrast
and 3:1 significant indicators as project goals. Native blur and window chrome
require real Windows/Linux/macOS sessions and must not be claimed from headless
Linux screenshots alone.
