# Проверки первого прототипа

Этот документ сохраняет результаты первого прототипа. Для новой Finder-сцены,
новых снимков и проверок настоящего Linux/X11-окна см. [FINDER_LINUX.md](FINDER_LINUX.md).
Settings и общий оконный слой: [SETTINGS_LINUX.md](SETTINGS_LINUX.md).

7 ноября 2026. Проверено в Linux Debian 13, GCC 14.2, Qt 6.8.2,
CMake 3.31.6, software renderer и offscreen QPA.

## Модуль и галерея

```sh
source /workspace/qt-sdk/activate.sh
cmake -S /workspace/Qt-MacOS -B /workspace/Qt-MacOS/build -G Ninja
cmake --build /workspace/Qt-MacOS/build --parallel 4
ctest --test-dir /workspace/Qt-MacOS/build --output-on-failure --no-tests=error
```

Сборка и CTest прошли. Quick Test: **22 passed, 0 failed, 0 skipped**,
из них 16 тестовых функций и 6 служебных init/cleanup outcomes.

Проверены mouse/keyboard activation и disabled-кнопка; checkbox;
редактирование текста; ComboBox с клавиатуры; поиск; смена темы;
выбор sidebar; фильтрация, кириллица и пустая выдача; сортировка;
выделение в списке/сетке с клавиатуры. Интеграционные тесты загружают
настоящий Main.qml: ввод в поиск изменяет модель браузера, кнопки меняют
представление и тему, стандартное сочетание Find фокусирует поиск.

SVG image plugin потребовалось дополнительно установить: отсутствие плагина
первоначально давало `Unsupported image format`. После установки
`qt6-svg-plugins` иконки отображаются и диагностических сообщений нет.
Начальная проверка темы также исправлена: цвет сравнивается как значение
после распространения QML binding, а не как изменяемая JS-обёртка.

## Изображения

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  ./build/qtmacos-gallery --screenshot docs/screenshots/dark.png
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  ./build/qtmacos-gallery --light --grid --screenshot docs/screenshots/light-grid.png
```

Оба запуска завершились с кодом 0. Изображения просмотрены; исправлены
контраст выбранного sidebar и заголовка сортировки, а также лишний scrollbar
у короткого списка. Это скриншоты реального Qt-приложения, не дизайн-макеты.

- [Тёмная тема, список](screenshots/dark.png)
- [Светлая тема, сетка](screenshots/light-grid.png)

Дополнительно успешно сохранены изображения с `QT_SCALE_FACTOR=1.5` и `2`:
1680×1080 и 2240×1440 соответственно. Это проверка рендеринга при масштабе,
не сертификат всех состояний интерфейса при каждом DPI.

## Obsidian

Baseline и отдельная сборка с пилотом прошли сборку, `qt-core` и smoke-генерацию
WAD. Пилот проверяет загрузку обёртки QtMacOS и связь темы с `backend.dark`;
исходные проверки генератора сохранены. Подробности и команды:
[OBSIDIAN_BASELINE.md](OBSIDIAN_BASELINE.md) и
[пилот интеграции](../integrations/obsidian/README.md).

## Что ещё не проверено и не реализовано

- Windows/macOS: добавлена CI-матрица, но здесь она не запускалась.
- Нативные декорации/материалы, blur, vibrancy, Snap, fullscreen и системная тема.
- Полная замена интерфейса Obsidian и глобальный Qt Quick Controls style:
  пока компоненты выбираются явно, пилот меняет только кнопки и поверхности.
- Меню, сложные редакторы, high contrast, active/inactive-палитры,
  производительность больших моделей и полноценная screen-reader проверка.
- Дистрибутивы и патчи Qt: пока нет подтверждённого ограничения, требующего форка.

Ничего не публиковалось; настройки среды при реализации не менялись.
