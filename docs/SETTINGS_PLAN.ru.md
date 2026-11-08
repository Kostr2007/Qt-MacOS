# Следующий этап: System Settings и общий macOS-подобный UI

8 ноября 2026. План по приложенному изображению страницы Mouse.
План составлен до реализации. Теперь экран Mouse и общий набор компонентов
реализованы; текущие снимки, API и результаты — в [SETTINGS_LINUX.md](SETTINGS_LINUX.md).
Будущие семейства интерфейса и расширенные проверки ниже остаются дорожной картой.

## Цель

Создать второй визуально проверяемый образец — Settings → Mouse на Linux.
После Finder это позволит выделить общий UI-набор по двум разным композициям,
а не распространять размеры и цвета одного окна на все интерфейсы.

Finder остаётся эталоном browser-окна. Приложенный Mouse — эталон preferences-окна.
Точная версия macOS и DPR по одному изображению не устанавливаются. Облик
фиксируется по снимку; современные рекомендации Apple используются для поведения
и семантики, а не для автоматической замены дизайна на Liquid Glass.

## Разбор изображения

Координаты приблизительно оценены по изображению 1090×962. Они не получены
пиксельным анализом оригинального файла. Это размеры растра образца, не готовые
logical px для любого дисплея.

| Часть | Наблюдение | Что требуется |
| --- | --- | --- |
| Оболочка | Светлый корпус, заметно округлённые углы, traffic lights слева | Общая оконная инфраструктура с отдельным preferences-профилем |
| Пропорции | Sidebar около x=0…337, примерно 31% ширины; окно почти квадратное | Не переносить Finder sidebar 15.5% и его соотношение сторон |
| Sidebar | Холодная светлая поверхность, поле поиска, группы цветных значков, собственный scrollbar | SettingsSidebar/SearchField/NavigationItem; прокрутка отдельно от формы |
| Выбранный пункт | Mouse на ярко-синем фоне, белая подпись | Отдельные active/inactive selection roles, не серое Finder-выделение |
| Header | Назад/вперёд в общей округлённой области, заголовок Mouse | PreferencesHeader без Finder action toolbar |
| Карточка | Примерно x=367…1055, y=96…458; слегка отличается от белого фона | SettingsGroup с мягким радиусом и очень тонкими внутренними разделителями |
| Tracking speed | Подпись слева, slider справа; заполненный track, белый thumb, риски, Slow/Fast | MacSlider с опциональными tick marks и подписями крайних значений |
| Natural scrolling | Заголовок + более светлое описание; switch справа, состояние OFF | SettingsRow с description и MacSwitch, а не CheckBox |
| Secondary click | Значение Click Right Side и вертикальные chevrons | MacPopupButton: меню выбора, а не SpinBox/числовой stepper |
| Double-Click Speed | Тот же slider, но иное текущее значение | Переиспользование одного контрола без копирования отрисовки |
| Scrolling Speed | Аналогичный slider | Третий независимый value на общей геометрии |
| Нижние действия | Advanced…, Set Up Bluetooth Mouse…, круглая ? | MacPushButton, HelpButton; actions вне карточки, выровнены справа |
| Свободное место | Большая белая область ниже формы | Сохранить композицию; не заполнять её демонстрационными настройками |

Визуально slider занимает около 360 px растра, switch — около 52×26,
строки формы имеют разную высоту: строка с description выше простой.
Отсюда нужен компонент строки с измеряемой высотой содержимого, а не один
фиксированный rowHeight для всех случаев.

## Общая архитектура

```text
QtMacOS
  WindowShell + WindowActions
    BrowserWindowProfile       → Finder
    PreferencesWindowProfile   → Settings
  Appearance / semantic tokens
  Primitives
    Slider, Switch, PopupButton, PushButton, HelpButton, SearchField
  Compositions
    SettingsSidebar, SettingsGroup, SettingsRow, SettingsPage
  Overlays
    PopupMenu, HelpPopover, Sheet, Alert
```

Оконные действия, resize, shadow и инфраструктура focus/accessibility общие.
Пропорции, радиусы, фон header и материал sidebar определяются профилем.
Проверенный Linux/X11 backend сохраняется; настоящие платформенные материалы
подключаются через отдельные capabilities с непрозрачным fallback.

Предлагаемые публичные контракты:

| Компонент | Основные свойства/события |
| --- | --- |
| MacSlider | from, to, value, stepSize, pressed, moved; optional tickCount, minimumText, maximumText |
| MacSwitch | checked, enabled, toggled; label/accessibility name |
| MacPopupButton | model, currentIndex, currentText, activated; menu placement and focus return |
| SettingsRow | title, description, control slot; content-driven implicitHeight |
| SettingsGroup | список строк, общие margins, separators только между строками |
| SettingsSidebar | model с section/icon/title, currentKey, searchText, activated |
| PreferencesWindow | title, navigation state, page slot, real WindowActions |

Контролы строить на публичных Qt Quick Controls/Templates. Сохранять штатные
value/checked/input/focus semantics, а не собирать все элементы из MouseArea.
Не копировать исходники Obsidian в UI-библиотеку и не привязывать компоненты
к backend.dark/backend.accent.

## Tokens и состояния

Текущий Theme имеет один selection и один rowHeight; этого недостаточно для
двух референсов. Ввести роли с сохранением совместимости текущих потребителей:

- window/content/sidebar/header/group backgrounds;
- primary/secondary/tertiary text, separator, focus ring;
- browser sidebar selection, preferences sidebar selection;
- active/inactive file selection; selected label/icon foreground;
- accent fill и текст на accent, switch track/thumb, slider track/fill/thumb;
- размеры body/caption/heading, padding строки, group spacing, corner roles.

Значения не разносить отдельными HEX по каждому контролу. При этом не создавать
универсальный фон, радиус и высоту для совершенно разных ролей. Новые значения
сначала проверяются в реальном Mouse-окне и regression Finder.

Для каждого контрола определить normal, hover, pressed/dragging, disabled,
keyboard focus; для переключателя — off/on, для меню — open/selected.
Switch различается не только цветом: thumb меняет положение. Тени thumb
должны оставаться мягкими, а hit area не обязана совпадать с тонким track.

## Порядок реализации

### 1. Зафиксировать сцены и выделить общую оболочку

- Сохранить текущие Finder dark/light снимки как regression baseline.
- Выделить из demo общие WindowActions и оболочку без изменения её поведения.
- Добавить preferences-профиль и пустую Mouse-страницу с правильной геометрией.
- Задать один reference viewport/DPR; воспроизвести исходные значения sliders
  и выключенный Natural scrolling.

Готово: обе сцены собираются; Finder сохраняет вид; Settings имеет нужные
пропорции и пустое пространство. Проверить оконные действия в Linux/X11.

### 2. Воспроизвести светлую Mouse-страницу целиком

- SettingsSidebar: поиск, группировка, цветные tiles и синий Mouse.
- PreferencesHeader, SettingsGroup/Row и разделители.
- Три sliders, switch, popup value и кнопки нижних действий.
- Оригинальные/разрешённые пиктограммы; не переиспользовать одинаковый значок
  для всех разделов. Inter остаётся переносимым приближением SF.

Готово: screenshot работающей Qt-сцены в сопоставимом масштабе; отдельно
сравнены оболочка, sidebar, форма, typography и controls. Не принимать этап
только по зелёным unit tests или наличию классов.

### 3. Добавить настоящее поведение и overlays

- Sliders работают drag, track click и клавишами; value корректно ограничен
  диапазоном и не сбрасывается при изменении размера окна.
- Switch переключается мышью/Space, сообщает checked и доступное имя.
- Popup показывает доступные варианты secondary click, закрывается по выбору
  и Escape, обновляет значение и возвращает фокус.
- Advanced… открывает sheet/диалог приложения, ? — help popover.
- Bluetooth action в демо открывает объясняющий диалог или явно отключён;
  не имитирует успешное подключение реального устройства.
- Модель параметров отделена от UI. Демонстрация не меняет настройки мыши Linux.
  При нужде сохранение состояния в отдельный demo config с явным reset.

Готово: реальные пользовательские сценарии проходят автоматические тесты;
есть снимки состояний меню, switch ON, focus и sheet. Самих этих overlays на
приложенном снимке нет: их дизайн проверять по дополнительным источникам,
не выдавать предположения за измерения референса.

### 4. Сделать контролы библиотечными и проверить вариации

- Перенести проверенные компоненты из сцены в QtMacOS с документированным API.
- Добавить компонентную галерею light/dark и состояний.
- Проверить 100/150/200%, длинные русские строки, увеличение шрифта,
  screen-reader roles/names, Tab/Shift+Tab и контраст.
- Dark Settings — отдельная разработанная вариация: исходный снимок подтверждает
  только светлую схему, точность тёмной потребует отдельного образца.

Готово: внешний пользователь подключает модуль без demo-зависимостей;
Finder regression и Settings tests проходят вместе.

### 5. Применить набор к Obsidian

Выбрать один реальный экран параметров: SettingsGroup/Row, slider для диапазона,
switch только для bool с корректной семантикой, popup для enum. Не превращать
каждый checkbox автоматически в switch. Сохранить схему параметров, генератор
и существующие тесты; повторить smoke-генерацию карты. Прежде полного редизайна
принять одну визуально и функционально законченную страницу.

### 6. Последующие семейства интерфейса

После этой итерации развивать по одному образцу на семейство:

1. Menus/popovers/sheets/alerts и фокус между ними.
2. Поля ввода, числовые editors/steppers, checkbox/radio и segmented controls.
3. Tabs, inspectors, trees/outlines и сложные таблицы для реальных экранов Obsidian.
4. Platform materials, системная тема и оставшиеся native integrations.

Для каждого семейства — reference, сцена, критерии поведения и visual regression.
Не начинать одновременно все системные приложения или переписывание qtbase.

## Проверки и критерии приёмки

- Для фиксированного растра сверять границы sidebar, формы, строк, slider и
  thumb; проектная цель ключевых границ — 1–2 px, а не процент общей похожести.
- Из-за возможного масштабирования/сжатия источника не подгонять JPEG blur
  и артефакты изображения в собственную отрисовку.
- Делать наложение и difference regions при наличии оригинального файла;
  не считать большой белый фон доказательством точности контролов.
- Снимать default, hover/focus, switch ON, открытое popup и advanced sheet.
- Functional tests: независимость трёх значений, min/max и keyboard slider,
  switch checked, enum activation, Escape/focus return, navigation/search,
  сохранение/reset demo-state, реальные WindowActions и Finder regression.
- Отдельно проверять accessibility и performance; не обещать desktop blur
  на Linux по картинке, снятой на контролируемом фоне.

## Организация задач

Это роли следующей реализации, не уже выполненная работа:

| Ответственный | Область | Когда начинать |
| --- | --- | --- |
| Координатор | WindowShell, tokens/API, CMake и интеграция | Первым; сохраняет Finder baseline |
| Дизайн/ресурсы | Геометрия Settings, цветные tiles, типографика | Параллельно первому этапу |
| Контролы | Slider/Switch/PopupButton + tests | После контракта tokens/API |
| Композиция | SettingsGroup/Row/sidebar и Mouse scene | После каркаса; контролы подключаются по мере готовности |
| Проверка | Visual regions, keyboard/focus и native smoke | По каждому завершённому срезу |

Один владелец каждого файла; не дублировать WindowShell в двух демонстрациях.
Библиотечный перенос выполняется после проверки сцены, а не вместо неё.

## Прочитанные официальные источники

- [Apple Sliders](https://developer.apple.com/design/human-interface-guidelines/sliders):
  fill по значению, направление min/max, tick marks в macOS.
- [Apple Toggles](https://developer.apple.com/design/human-interface-guidelines/toggles):
  изменение состояния, понятная подпись и индикация не только цветом.
- [Apple Pop-up buttons](https://developer.apple.com/design/human-interface-guidelines/pop-up-buttons):
  выбор из меню и отображение выбранного значения.
- [Apple Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons):
  иерархия действий, pressed state и системные взаимодействия.
- [Apple Settings](https://developer.apple.com/design/human-interface-guidelines/settings):
  настройки по смыслу задачи и разумные значения по умолчанию.

Страницы прочитаны через официальные DocC JSON. Их современные варианты
содержат рекомендации для разных поколений дизайна; внешний вид берётся
из предоставленного изображения, а рекомендации применяются по назначению.
