# Obsidian: исходное состояние перед интеграцией Qt-MacOS

Дата: 7 ноября 2026. Проверяемый commit:
`7a9391a28e5ba21f088b164be488ead6d88c00fb`.

Исследовательская копия находится в `/tmp/obsidian-audit`; это не подключённый
репозиторий проекта Qt-MacOS. Во время описанного baseline tracked исходники
этой копии не изменялись. После baseline в этой же временной копии проверен
отдельный пилот: [патч и его результаты](../integrations/obsidian/README.md).
Результаты ниже относятся к исходному приложению до применения этого патча.

## Среда и команды

Debian 13 x86_64, GCC 14.2, Qt 6.8.2, CMake 3.31.6, Ninja 1.12.1, Flex 2.6.4.
Использован локальный SDK `/workspace/qt-sdk`, подготовленный из подписанных
пакетов Debian. Следующие пути относятся к текущей облачной машине:

```sh
source /workspace/qt-sdk/activate.sh
export M4=/workspace/qt-sdk/root/usr/bin/m4
cd /tmp/obsidian-audit
OBSIDIAN_BUILD_JOBS=4 ./scripts/dev/build-linux.sh
```

Скрипт запускает CMake с `-DOBSIDIAN_QT=ON`, Release и Ninja, затем сборку с
четырьмя параллельными процессами. CMake требует Flex даже при наличии
`source_files/filename_formatter/lex.yy.c`. Для сборки потребовались Qt Base и
Declarative development packages. QML-модули Quick, Controls, Layouts, Dialogs,
Templates, Window, QtQml Models и WorkerScript нужны при загрузке интерфейса.

CMake POST_BUILD копирует исполняемые файлы в корень исследовательской копии
(`obsidian`, `obsidian-engine`) и `tools/qsavetex`. Перед запуском проверено,
что рабочая копия чистая. Это ожидаемые generated outputs, не изменения исходников.

## Проверки

| Проверка | Результат текущего запуска |
| --- | --- |
| Документированная Release-сборка | PASS, 204/204 targets, exit 0 |
| CTest `qt-core` | PASS, 1/1 suite, exit 0, 7.24 s |
| QtTest внутри `qt-core` | 12 passed, 0 failed, 0 skipped; включая init/cleanup, 10 содержательных test functions |
| Запуск приложения `--smoke-output` | PASS, exit 0, QML загружен, реальная карта сгенерирована |
| Отчёт и артефакты smoke | `success: true`, Qt 6.8.2, 59 modules, WAD 2 477 357 bytes с magic `PWAD`, CONFIG.txt существует |
| Tracked/untracked изменения после сборки и тестов | `git status --short` пуст; generated outputs игнорируются репозиторием |

Команды тестирования:

```sh
QT_QUICK_BACKEND=software ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
smoke_dir=$(mktemp -d /tmp/obsidian-baseline-smoke.XXXXXX)
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software ./obsidian --smoke-output "$smoke_dir"
```

`qt-core` проверяет schema/navigation/search, сохранность неизвестных параметров,
конфигурацию и транзакционность ошибочного импорта, binary/UDMF WAD, настоящую
генерацию, зависимости и presets, отмену и ошибку отсутствующего worker.
Отчёт standalone smoke прочитан из нового уникального каталога текущего запуска:
`/tmp/obsidian-baseline-smoke.o7mGY3/qt-smoke.json`. Проверены magic и размер
результирующего WAD, а не только код процесса или наличие файла отчёта.

Логи текущей машины: `/tmp/obsidian-baseline-build.log`,
`/tmp/obsidian-baseline-ctest.log`, `/tmp/obsidian-baseline-smoke.log` и
`build/qt/Testing/Temporary/LastTest.log` в исследовательской копии.

`scripts/dev/check-qt.py` **не запускался**: Xvfb и xdotool отсутствуют.
Это дополнительный сценарий настоящего X11-окна с F2, поиском и resize.
Оригинальные оконные скриншоты, аппаратный renderer, Wayland, Windows и macOS
не проверены. Приведённые результаты относятся к Linux offscreen/software.

## Границы будущей интеграции

- `source_files/qt_frontend/CMakeLists.txt`: Qt >= 6.4, Quick, QuickControls2,
  Test и C++17. Сюда подключается отдельный QML-модуль, а не Qt Widgets style.
- `main.cpp`: `QQuickStyle::setStyle("Fusion")` перед загрузкой QML. Выбор
  глобального стиля в будущем должен происходить здесь; компоненты первого
  прототипа QtMacOS подключаются явно и могут использоваться без смены стиля.
- `Main.qml`: структура окна и жёсткие палитры. Начальный пилот — один экран
  «Геометрия», боковая панель, toolbar и один редактор параметра.
- `ActionButton.qml` и `Surface.qml`: собственные фоны перекрывают глобальный
  стиль. Их следует перевести на tokens/компоненты QtMacOS.
- `Backend`, схема параметров, отдельный `obsidian-engine`, Lua/C++ генератор,
  формат конфигурации и пользовательские данные не требуют изменений ради темы.

Документация Obsidian пока не считает Windows/macOS deployment и нативный
Wayland проверенными. Успешная Linux-сборка не подтверждает эти платформы.

## Источники

- [Исходники проверенного commit](https://github.com/Kostr2007/Obsidian-level-maker-extended/tree/7a9391a28e5ba21f088b164be488ead6d88c00fb)
- `scripts/dev/build-linux.sh`, `scripts/dev/check-qt.py`
- `source_files/qt_frontend/tests/test_core.cpp`
- `docs/qt6/ARCHITECTURE.md`, `docs/qt6/UBUNTU.md`
