# Минимальный пилот Qt-MacOS в Obsidian

`qtmacos.patch` подготовлен и проверен для commit
`7a9391a28e5ba21f088b164be488ead6d88c00fb` репозитория
[Obsidian-level-maker-extended](https://github.com/Kostr2007/Obsidian-level-maker-extended).
Это переносимый артефакт для ревью и применения в отдельной рабочей копии.
Изменения не отправлены в GitHub и не применены к опубликованной среде.

## Что меняется

- Опциональный CMake-параметр `OBSIDIAN_QTMACOS_ROOT` подключает исходники модуля
  через `add_subdirectory` и линкует его статический QML plugin.
- Включённый пилот выбирает Basic до загрузки QML. Два presentation-компонента
  заменяются: `ActionButton` использует `MacButton`, `Surface` — tokens темы.
- QRC-wrapper наследует исходный `Main.qml` как `BaseMain` и связывает
  `Theme.dark` с `backend.dark`. Существующие методы окна сохраняются.
- Guarded-проверки в существующем UI-тесте подтверждают, что загружен wrapper и
  тема действительно меняется при изменении backend preference.
- С пустым параметром используются исходные QML и Fusion; QtMacOS не требуется.

Backend, протокол, генератор, конфигурация и пользовательские данные не меняются.
Остальная палитра/композиция окна пока остаётся исходной. Это проверка подключения
двух компонентов, а не завершённый редизайн Obsidian. Accent preference приложения
ещё не отображается в tokens QtMacOS, которые пока используют собственный accent.

## Применение и сборка

В чистой рабочей копии соответствующего commit:

```sh
git apply --check /path/to/Qt-MacOS/integrations/obsidian/qtmacos.patch
git apply /path/to/Qt-MacOS/integrations/obsidian/qtmacos.patch
cmake -S . -B build/qt-macos -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DOBSIDIAN_QT=ON -DOBSIDIAN_QTMACOS_ROOT=/path/to/Qt-MacOS
cmake --build build/qt-macos --parallel 4
QT_QUICK_BACKEND=software ctest --test-dir build/qt-macos \
  --output-on-failure --no-tests=error -R '^qt-core$'
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  ./obsidian --smoke-output /path/to/new-empty-smoke-directory
```

На другой ревизии сначала изучите diff и результат `git apply --check`; не
применяйте патч поверх пользовательских изменений вслепую. Нужны зависимости
сборки Obsidian и QtMacOS; см. README основного модуля и baseline-документ.
В текущей облачной машине перед командами используется
`source /workspace/qt-sdk/activate.sh` и
`export M4=/workspace/qt-sdk/root/usr/bin/m4`.

CMake Obsidian копирует executable в корень исходников после сборки. Запускать
сборку следует в рабочей копии, где эти выходные файлы не затрут пользовательские
файлы. Выключение пилота: сконфигурировать дерево с
`-DOBSIDIAN_QTMACOS_ROOT=` и пересобрать.

## Проверено в текущем запуске

Debian 13 x86_64, GCC 14.2, Qt 6.8.2, CMake 3.31.6, software/offscreen:

| Проверка | Результат |
| --- | --- |
| Исходный Obsidian до патча | Release build PASS; qt-core 1/1; standalone smoke PASS |
| Пилот с модулем | Release build PASS, 247 начальных targets + incremental rebuild после правок модуля |
| `qt-core` с пилотом | PASS, 1/1 suite; QtTest 12 passed, 0 failed, 0 skipped (10 содержательных функций + init/cleanup), 6.93 s |
| Обнаружение пилота и смена темы | PASS, проверяются дополнительными guarded assertions |
| Standalone generation с пилотом | PASS, exit 0, report success=true, 59 modules, WAD 2 437 779 bytes с `PWAD`, CONFIG.txt существует |
| Применимость артефакта | `git apply --check` PASS на свежих файлах из указанного HEAD |
| Пилот выключен после применения патча | Configure/build с пустым `OBSIDIAN_QTMACOS_ROOT` PASS; qt-core 1/1 PASS, 6.83 s, исходные QML/Fusion |

Отчёт нового smoke-запуска:
`/tmp/obsidian-pilot-smoke.8ykhO5/qt-smoke.json`.
Логи: `/tmp/obsidian-pilot-build.log`, `/tmp/obsidian-pilot-ctest.log`,
`/tmp/obsidian-pilot-smoke.log`, `/tmp/obsidian-pilot-off.log`.

Проверки подтверждают загрузку QML и сохранность сценариев. Визуальные сравнения
Obsidian, нативное оконное поведение, Windows и macOS здесь не проверены.
Следующий этап интеграции — tokens оставшейся палитры, sidebar/toolbar и один
полный редактор параметра с отдельным визуальным сравнением.
