# Qt-MacOS v0.2.0 — Interaction Preview

Qt-MacOS is a reusable Qt Quick component library with Finder, Settings, layout
and Motion Lab galleries. This release adds detailed interaction feedback to
the existing macOS-inspired appearance.

- Oval slider thumbs with bounded visual follow and coordinated track fill.
- Smooth sidebar and popup-menu selection with interruptible spring motion.
- Capsule history controls, category transitions, anchored help and tooltips.
- Search clearing, empty results, keyboard navigation and inactive window states.
- Switch feedback and optional on/off symbols; reduced-motion support.
- Original vector icons, overlay scrollbars, recording and frame-inspection tools.

[Screenshots and videos](MEDIA_GALLERY.md) · [Build and integrate](GETTING_STARTED.md) ·
[Changelog](../CHANGELOG.md) · [Validation](RELEASE_VALIDATION_v0.2.0.md).

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --parallel 4
ctest --test-dir build -C Release --output-on-failure --no-tests=error
./build/qtmacos-gallery --settings
./build/qtmacos-gallery --motion-lab
```

For multi-config builds use the executable in `build/Release`. A matching Qt 6
kit with Quick, Quick Controls 2 and Quick Test is required. CI uses Qt 6.8.2;
current local validation uses Qt 6.12.0 on NixOS/X11. The declared Qt minimum
remains 6.4 and is not independently validated.

This is a **source-only pre-release**: public APIs may change in later 0.x
versions. Mouse preferences are held in memory and do not change OS settings.
Native macOS/Windows behavior, Wayland, real vibrancy/Liquid Glass and a full
screen-reader audit remain outside the verified scope. i3 maximize behavior
has a known limitation recorded in the validation notes.

Original code/documentation is MIT; Inter is OFL-1.1, Phosphor is MIT, and the
optional Obsidian integration patches retain GPL-2.0-or-later notices.
See [third-party notices](../THIRD_PARTY_NOTICES.md).

## По-русски

Выпуск 0.2.0 переносит доработки поведения в публичную библиотеку: плавное
выделение и движение, аккуратные контролы, поиск и клавиатуру, справку и
различимые состояния. Добавлены реальные изображения и видео, а также инструменты
повторной записи. Это обновление исходников, а не готовые переносимые binaries.
