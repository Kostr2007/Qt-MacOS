# Settings → Mouse на Linux

8 ноября 2026. Реализация следующей сцены по SETTINGS_PLAN.ru.md.

## Запуск и снимки

```sh
source /workspace/qt-sdk/activate.sh  # только в подготовленной облачной среде
cmake -S . -B build -G Ninja
cmake --build build --parallel 4
./build/qtmacos-gallery --settings
```

Обычный запуск без --settings по-прежнему открывает Finder. Settings по умолчанию
светлый; --dark выбирает разработанную тёмную вариацию. Ctrl+Shift+L переключает
схему, Ctrl+F переводит фокус в поиск разделов.

- [Mouse, светлая схема](screenshots/settings-linux-light.png)
- [Тёмная вариация](screenshots/settings-linux-dark.png)
- [Switch ON и открытое меню](screenshots/settings-linux-popup.png)
- [Advanced](screenshots/settings-linux-advanced.png)
- [X11-снимок на этапе проверки оболочки](screenshots/settings-linux-x11.png)

Первые четыре снимка получены из работающего приложения с software renderer.
Синий фон добавляется --presentation для проверки скруглений и тени; это не
desktop blur. В обычном режиме поле вокруг оболочки прозрачное.

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  ./build/qtmacos-gallery --settings --presentation --screenshot /tmp/settings.png
```

Для воспроизводимых снимков состояний доступны --advanced, --natural-on и
--secondary-menu. Настоящие клики и клавиатура проверяются отдельно тестами.
Исходный образец задаёт светлую Mouse-страницу; dark и overlays — наши вариации,
не измеренные копии дополнительных скриншотов Apple.

## Реализованный интерфейс

- Оболочка видимого размера 1000×862 с preferences-радиусом 40 и sidebar 306.
- Общая с Finder инфраструктура теней, alpha, оконных действий и resize.
- Поиск по разделам, цветные оригинальные tiles, прокрутка и синий Mouse.
- Карточка из пяти строк; label и slider track выровнены независимо от captions.
- Три независимых значения: tracking, double-click, scrolling; drag, track click,
  клавиши-стрелки и ограничение диапазона.
- Natural scrolling: mouse/Space, disabled, движение thumb, доступное имя.
- Secondary click: меню, мышь/клавиатура, selected value, Escape/focus return.
- Advanced: модальный диалог, pointer acceleration и Reset.
- Help: закрываемый popover. Bluetooth: объясняющий диалог без сканирования
  и подключения реальных устройств.
- Навигация назад/вперёд сохраняет значения страницы.

Другие разделы sidebar открывают обозначенную заглушку с возвратом к Mouse.
Значения живут в памяти окна и сбрасываются после его закрытия. Файлы настроек
и параметры мыши Linux не изменяются.

## Публичный модуль

Новые типы экспортируются через `import QtMacOS` и не импортируют demo:

| Тип | Назначение / API |
| --- | --- |
| MacWindow | ApplicationWindow с surface slot, surfaceColor, normalRadius, shadowMargin, zoom() |
| WindowButtons | Три кнопки и сигналы closeRequested/minimizeRequested/zoomRequested |
| MacDialog | Модальный диалог с заголовком, скруглением и стилизованным стандартным button box |
| MacSlider | Стандартные from/to/value/stepSize/moved, minimumText/maximumText/tickCount |
| MacSwitch | checked/toggled/enabled и штатная клавиатура |
| MacPopupButton | model/currentIndex/currentText/activated и popup |
| MacPushButton / MacHelpButton | Компактная кнопка и круглый Help |
| SettingsGroup | rows slot; padding либо horizontalPadding/verticalPadding |
| SettingsRow | title/description, controls slot, controlWidth/rowHeight, labelOffset/controlOffset |
| SettingsSidebar | entries/currentKey/searchText/navigate(key)/focusSearch() |
| SettingsIcon | Оригинальные Canvas-символы для tiles |

Размер MacWindow включает поле тени; вложенные элементы размещаются в его
surfaceItem, а не на всём внешнем прямоугольнике. Оконные кнопки добавляются
потребителем в нужное место. Inter поставляется ресурсом самого модуля.

SettingsSidebar получает данные извне: entries — массив объектов с key, icon,
tint и опциональным gap. Список системных разделов находится в demo/SettingsMain,
а не внутри общего компонента. Поиск/клик возвращают key; код приложения решает,
какая страница ему соответствует.

Пример композиции:

```qml
SettingsGroup {
    width: 640
    SettingsRow {
        title: qsTr("Tracking speed")
        controlWidth: 300
        MacSlider {
            width: parent.width
            value: 0.45
            Accessible.name: qsTr("Tracking speed")
            onMoved: console.log(value)
        }
    }
}
```

В controls slot высота вычисляется по childrenRect; задавайте контролу width,
а не anchors.fill для контейнера, чья высота зависит от самого контрола.
Theme.settings* содержит отдельные семантические роли. Старые Theme-поля сохранены.
Глобальная замена всех Qt Quick Controls на собственный style ещё не выполнена.

## Доказательства проверок

Debian 13, GCC 14.2, Qt 6.8.2:

- CMake/Ninja build — PASS.
- qmllint всех demo и библиотечных QML — PASS, без предупреждений.
- CTest — PASS; Quick Test **39 passed, 0 failed, 0 skipped**:
  31 тестовая функция и 8 init/cleanup outcomes.
- Новые проверки используют настоящее Mouse-окно: независимость sliders,
  pointer и keyboard bounds, switch, disabled controls, popup выбор и Escape,
  Reset с проверкой обновления UI, overlays, navigation/search, смена темы
  без потери значений и закрытие окна. QML warnings считаются ошибками.
- Finder dark screenshot после выделения общей оболочки пиксельно идентичен
  прежнему docs/screenshots/finder-linux-dark.png при тех же условиях.
- Settings screenshot runs при 150% и 200% завершились успешно; размеры
  1572×1365 и 2096×1820. Это проверка рендеринга, не полная проверка accessibility.
- Существующий Obsidian pilot пересобран с обновлённым модулем; qt-core PASS,
  1/1 suite, 12 QtTest outcomes, без runtime QWARN. Его интерфейс в этой итерации
  не переводился целиком на новую страницу настроек.

Выявленные при проверке проблемы исправлены: подписи captions смещали строки;
Basic popup давал плохой контраст выбранного пункта. Popup теперь имеет явную
семантику выделения и проверку выбора мышью. Первоначальная тестовая гипотеза
про Home/End у Basic Slider заменена проверкой документированных стрелок и
реального достижения min/max; Home/End не заявлены как поддерживаемые shortcuts.

### Настоящее управление окнами X11

Xvfb 1500×1100 + Openbox + Picom, scripts/native_window_smoke.py:

| Проверка | Settings | Finder после выделения общей оболочки |
| --- | --- | --- |
| Maximize | 1048×910 → 1500×1100 | 1148×724 → 1500×1100 |
| Restore | 1048×910 | 1148×724 |
| Drag | (226,95) → (296,135) | (176,188) → (246,228) |
| Resize | 1000×870, с учётом minimumWidth | 1078×684 |
| Minimize / restore | PASS, проверено HIDDEN | PASS |
| Close | exit 0 | exit 0 |

```sh
python3 scripts/native_window_smoke.py build/qtmacos-gallery /tmp/result.json /tmp/desktop.png --settings
```

Прогон требует X11-сессию с WM, xdotool/xprop и Pillow для снимка. Отчёты текущей
машины: /tmp/settings-native-result.json и /tmp/finder-shared-native-result.json.

## Оставшиеся границы

Настоящие vibrancy/backdrop blur, Wayland и другие ОС не проверены этим прогоном.
Inter приближает, но не воспроизводит SF. Полный screen-reader audit, увеличение
шрифта, high contrast, Reduced Motion и системное следование теме остаются
следующими работами. Снимок-референс не доступен оригинальным файлом на диске:
автоматический pixel diff с ним не выполнялся, процент сходства не заявляется.
Ничего не публиковалось и конфигурация облачной среды не менялась.
