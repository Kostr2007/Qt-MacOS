# Layout & organization: реализация и доказательства

8 ноября 2026. Первый функциональный срез всех десяти запрошенных семейств.
Это развитие собственного Qt Quick модуля; исходники qtbase не изменялись.

## Что обобщено

11 публичных типов используют общий Theme, доступные имена/роли и базовые
Qt Quick механизмы ввода. Компоненты не импортируют demo или Obsidian backend.

| Семейство | Реализация |
| --- | --- |
| Boxes | MacBox: необязательный внешний заголовок, content slot, padding/spacing, высота по содержимому |
| Collections | MacCollectionView: виртуализированный GridView, адаптация числа колонок, keyboard и стабильный selectedId |
| Column views | MacColumnBrowser: путь из модели, списки уровней, breadcrumbs, стрелки, горизонтальная прокрутка, drag-resize отдельных колонок |
| Disclosure | MacDisclosureGroup: настоящий ToolButton, Space/Enter, сохранённые дети, возврат фокуса при скрытии, reducedMotion |
| Labels | MacLabel: роли Title/Heading/Body/Secondary/Caption, перенос строк, семантические цвета |
| Lists/tables | MacListView + MacTableView: виртуализация, выбор по ID, sortable header, resize и общая геометрия header/cells |
| Lockups | MacLockup: одна основная область действия, original Canvas artwork, title/subtitle, focus/selection; адаптация tvOS |
| Outline | MacOutlineView: настоящий TreeView, раскрытие, keyboard, восстановление ветвей после reset, возврат выбора к свёрнутому предку |
| Split | MacSplitView: настоящий SplitView, min sizes, handles, collapse/restore и перенос фокуса из скрываемой панели |
| Tabs | MacTabView: управляемый currentKey, сохраняемые Loader-страницы, keyboard, overflow/scroll-to-focus |

Полное описание источников и применимости платформ: HIG_LAYOUT_SOURCES.md.
Lockups у Apple — tvOS-only. Семантические роли нашего API и переносимые
адаптации не выдаются за названия или сертификацию AppKit-компонентов.

## Данные отдельно от представлений

В QtMacOS.Demo зарегистрирован WorkspaceModel: QAbstractItemModel с иерархией
и плоской проекцией entries. Это отдельный модуль примеров, а не зависимость
публичного QtMacOS. Он позволяет проверить одни компоненты на studio/library,
при добавлении, удалении, переименовании, фильтрации и сортировке.

Общий контракт записей: itemId, title, subtitle, kind, tint; таблица читает
display по колонкам. selectedId принадлежит контроллеру. Представления выдают
selectionRequested(id), сохраняя внешние binding. Изменение порядка не меняет
идентичность выбранного ресурса.

Для иерархических представлений нужен адаптер с childrenFor(parentId),
pathFor(id), indexForId(id), itemIdForIndex(index) и уведомлением revision.
Это явный контракт; произвольный QAbstractItemModel без адаптера нельзя считать
автоматически совместимым с нашим ID-based API. Другие Qt-модели могут подключать
list/table через роли и необязательный rowIdProvider.

Пример применения вне галереи:

```qml
MacCollectionView {
    model: controller.assets
    selectedId: controller.selectedAssetId
    onSelectionRequested: id => controller.selectedAssetId = id
}
```

MacColumnBrowser.columnWidth задаёт исходную ширину; columnWidths хранит размеры
по стабильному parentId, resizeColumn(parentId,width) ограничивает 144…500 px.
MacSplitView сохраняет публичные attached properties стандартного SplitView.
MacTabView принимает tabs:[{key,title}] и pageDelegate с pageKey/tabData;
страницы остаются созданными, пока соответствующая вкладка существует.

## Галерея и снимки

```sh
source /workspace/qt-sdk/activate.sh
cmake -S . -B build -G Ninja
cmake --build build --parallel 4
./build/qtmacos-gallery --layout --page collections
./build/qtmacos-gallery --layout --page columns --state active
./build/qtmacos-gallery --layout --page labels --dataset library --narrow --dark
```

Варианты --state служат воспроизводимой визуальной проверке. Они не считаются
записью действий пользователя. Отдельная последовательность кадров снимается
внутри QtTest после реального pointer/keyboard ввода:

```sh
QTMACOS_STORY_DIR="$PWD/docs/screenshots/layout-interactions" \
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  ./build/qtmacos-tests
```

Эта опция только сохраняет дополнительные кадры теста. Без неё выполняются
те же поведенческие assertions. Переключение collection/list и выбор родительской
ветки частью сценариев выполняются через контроллер; выбор карточки, сортировка,
вкладки, текст, disclosure и drag-разделитель — через события ввода.

Ссылки на все фотографии, HTML и manifests: [LAYOUT_GALLERY.md](LAYOUT_GALLERY.md).
Синий presentation backdrop — контролируемый фон, не desktop blur.

## Проверки

Linux Debian 13, Qt 6.8.2, GCC 14.2, software renderer:

- CMake/Ninja build и две CTest suites проходят.
- QML Quick Test: 74 passed, 0 failed, 0 skipped; 58 содержательных тестовых
  функций плюс 16 init/cleanup outcomes. Сохранены Finder/Mouse проверки.
- C++ WorkspaceModel: 6 passed — четыре тестовых функции плюс init/cleanup.
  QAbstractItemModelTester проверяет дерево и проекцию, включая reset/mutations.
- 10 000 записей проверены в модели и в настоящем MacCollectionView:
  меньше 150 visual children до и после End-навигации, выбор последнего ID корректен.
  Это доказательство виртуализации данного сценария, не измерение FPS.
- Проверены сортировка с сохранением выбора, реальные display-ячейки,
  передача выбора между представлениями, rename/remove/filter, alternative dataset,
  adaptive collection, path keyboard, column drag, outline collapse/reset,
  split focus/restore, long-tab keyboard visibility и сохранение draft.
- В обновлённых интеграционных QML-тестах runtime warnings являются ошибкой.
- qmllint нового интерфейса и библиотечных Mac*-компонентов проходит.
- Finder dark и Mouse light после расширения модуля пиксельно идентичны
  своим сохранённым Linux-эталонам при тех же условиях.

Снимки обнаружили ошибки, которых не было видно в изолированных fixtures:
пустые таблицы из-за неэкспортированного display role; Unicode disclosure glyph
вместо нейтрального вектора. Обе исправлены. Добавлена проверка display role в
C++ и реального текста ячеек в QML. Также исправлен отложенный callback после
уничтожения дерева: QModelIndex заново разрешается из ID, старый не захватывается.
Для старых Qt сохранён fallback, а на 6.8 используется современный index().

В локальном Qt6Test QAbstractItemModelTester выдаёт предупреждение invalid type
4097 при конструировании; оно воспроизведено и на минимальном отдельном harness.
Assertions модели проходят, приложение и финальные кадры не дают этого сообщения.
Полные QML-логи: /tmp/layout-story-tests.txt; модель: /tmp/layout-final-model-tests.txt.

### Оконный менеджер

Новая галерея проверена настоящим X11-клиентом на Xvfb 1500×1100, Openbox/Picom:
maximize 1280×880 → 1500×1100, restore, drag (110,110) → (180,150),
resize → 1210×840, minimize/HIDDEN и close с exit 0. Отчёт:
/tmp/layout-native-result.json. Это не проверка Wayland или других ОС.

## Настоящий потребитель: Obsidian

В существующую панель пояснения параметра подключены MacLabel, MacBox и
MacDisclosureGroup. Значение приходит из живой schema/backend; изменение
параметра обновляет UI, справка раскрывается и сохраняет контекст.

[Патч, снимок и результаты](../integrations/obsidian/LAYOUT_PILOT.md).
Пилот включается отдельно; его OFF-путь сохраняет исходный frontend.
ON/OFF прошли qt-core; ON также прошёл генерацию настоящего PWAD с 59 modules.
Это ограниченная рабочая панель, а не полный редизайн Obsidian.

## Границы этого среза

Это первая переносимая реализация основных контрактов и состояний. В неё
не входят полный AppKit parity, нативные материалы, полный screen-reader audit,
все режимы увеличения текста, high contrast и проверки Windows/macOS/Wayland.
Multiple selection, перетаскивание ресурсов, editable table cells, document tabs
с unsaved prompts и расширенная сортировка дерева требуют отдельных сценариев.

Inter и original vector artwork приближают стиль, но не превращают Linux-renderer
в системный macOS. Современный Liquid Glass не подменяет выбранный профиль.
Публикация и изменения конфигурации среды не выполнялись.
