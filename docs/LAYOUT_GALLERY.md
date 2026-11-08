# Галерея структуры и организации

Галерея переносит принципы macOS в повторно используемые компоненты Qt Quick:
иерархию, выравнивание, контекст выбора, раскрытие деталей и устойчивую навигацию.
Отдельные Finder и Settings остаются примерами применения этих компонентов.
Исходный ориентир — [Apple HIG: Layout and organization](https://developer.apple.com/design/human-interface-guidelines/layout-and-organization).

## Реализованная галерея

[Открыть HTML-галерею всех 40 кадров](screenshots/layout/20261108T074438Z-yxe0jxah/index.html) ·
[Manifest с командами и хешами](screenshots/layout/20261108T074438Z-yxe0jxah/manifest.json) ·
[API, проверки и ограничения](LAYOUT_IMPLEMENTATION.ru.md) ·
[Проверенные материалы Apple](HIG_LAYOUT_SOURCES.md)

Каждый кадр получен от реального приложения. Активное состояние CLI показывает
выбранный/раскрытый вариант. Отдельные последовательности ниже записаны во время
настоящих mouse/key тестов.

| Семейство | Светлая схема | Тёмная схема | Состояние | Другие данные / узкое окно |
| --- | --- | --- | --- | --- |
| Boxes | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/boxes-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/boxes-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/boxes-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/boxes-narrow-library.png) |
| Collections | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/collections-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/collections-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/collections-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/collections-narrow-library.png) |
| Column views | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/columns-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/columns-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/columns-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/columns-narrow-library.png) |
| Disclosure controls | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/disclosure-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/disclosure-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/disclosure-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/disclosure-narrow-library.png) |
| Labels | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/labels-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/labels-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/labels-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/labels-narrow-library.png) |
| Lists and tables | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/lists-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/lists-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/lists-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/lists-narrow-library.png) |
| Lockups — tvOS adaptation | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/lockups-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/lockups-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/lockups-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/lockups-narrow-library.png) |
| Outline views | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/outline-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/outline-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/outline-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/outline-narrow-library.png) |
| Split views | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/split-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/split-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/split-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/split-narrow-library.png) |
| Tab views | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/tabs-light-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/tabs-dark-default.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/tabs-light-active.png) | [Фото](screenshots/layout/20261108T074438Z-yxe0jxah/tabs-narrow-library.png) |

## Последовательности реальных действий

Это кадры QtTest, захваченные после действий и соответствующих assertions,
а не дорисованные состояния:

- Выбор карточки → другое представление тех же данных → сортировка с сохранением выбора:
  [1](screenshots/layout-interactions/01-collection-selection.png),
  [2](screenshots/layout-interactions/02-shared-selection.png),
  [3](screenshots/layout-interactions/03-sorted-with-selection.png).
- Ввод текста → переключение вкладки → возврат с сохранённым текстом:
  [4](screenshots/layout-interactions/04-entered-draft.png),
  [5](screenshots/layout-interactions/05-switched-page.png),
  [6](screenshots/layout-interactions/06-retained-draft.png).
- Раскрытие с клавиатуры и изменение формата → сворачивание:
  [7](screenshots/layout-interactions/07-keyboard-expanded.png),
  [8](screenshots/layout-interactions/08-keyboard-collapsed.png).
- Перетаскивание разделителя колонки с сохранением пути:
  [9](screenshots/layout-interactions/09-column-resized.png).
- Проход по уровням иерархии стрелками:
  [10](screenshots/layout-interactions/10-column-keyboard-path.png).

[Manifest кадров взаимодействия](screenshots/layout-interactions/manifest.json).

## Применение в настоящем приложении

В панели пояснения параметра Obsidian используются общие MacLabel, MacBox и
MacDisclosureGroup. Значения приходят из backend, генератор и редакторы параметров
сохранены: [снимок](../integrations/obsidian/layout-inspector.png),
[патч и результаты](../integrations/obsidian/LAYOUT_PILOT.md).

## Что проверять в каждой сцене

| Страница CLI | Компонент и принцип | Что должно быть видно и проверяться |
| --- | --- | --- |
| `boxes` | Boxes: объединение связанных настроек | Общий заголовок группы, отступы и второстепенный текст; изменение элемента не меняет соседнюю группу. |
| `collections` | Collections: одинаковые элементы с визуальным содержимым | Сетка, подписи, выбор и изменение числа колонок при сужении; большие модели проверяются отдельно от фотографий. |
| `columns` | Column views: путь по иерархии | Выбор в колонке определяет содержимое следующей; смена родителя убирает устаревший путь. |
| `disclosure` | Disclosure controls: постепенное раскрытие | Закрытые детали не занимают место; раскрытие показывает связанные настройки и сохраняет ясный заголовок. |
| `labels` | Labels: ясное именование и иерархия | Основная подпись, пояснение и значение различаются по роли; длинные значения и другой набор данных сохраняют читаемость. |
| `lists` | Lists and tables: сравнение записей | Заголовки колонок, выравнивание значений и выделение строки; сортировка, поиск и клавиатура требуют поведенческой проверки. |
| `lockups` | Lockups: связанная группа изображения и подписи | Контент воспринимается как единый элемент; состояние выбора согласует изображение и текст. Платформенная оговорка ниже. |
| `outline` | Outline views: дерево объектов | Отступы показывают уровни, disclosure отделён от выбора; раскрытие и навигация должны работать на реальной модели. |
| `split` | Split views: соседние области с разными ролями | Навигация и детали разделены; размеры, узкое окно и выбор сохраняют доступность содержимого. |
| `tabs` | Tab views: альтернативные представления одного контекста | Выбранная вкладка различима; переключение меняет содержимое, сохраняет общий контекст и доступно с клавиатуры. |

Таблица задаёт критерии обзора; сама по себе она не удостоверяет прохождение
проверок. Реализованные состояния следует сверять с кодом галереи и результатами
CTest. Вариант `active` — воспроизводимое состояние сцены для снимка, а не запись
пользовательского взаимодействия.

## Воспроизводимые настоящие снимки

После сборки выполните из корня репозитория:

```sh
source /workspace/qt-sdk/activate.sh
python3 scripts/capture_layout.py --binary build/qtmacos-gallery \
  --output docs/screenshots/layout --timeout 30
```

SDK активируется только там, где он установлен по этому пути. На другой машине
используйте настроенный Qt SDK и путь к своей сборке. Скрипт сохраняет переменные
поиска Qt/QML и библиотек из окружения, явно выбирая `offscreen` и `software`.
Дополнительных Python-пакетов не требуется. Альтернативное имя параметра
исполняемого файла — `--binarypath`.

Для короткой проверки:

```sh
python3 scripts/capture_layout.py --binary build/qtmacos-gallery \
  --pages boxes columns split --output /tmp/qtmacos-layout
```

Каждая страница снимается в четырёх вариантах:

| Вариант | Данные | Состояние | Дополнительные параметры |
| --- | --- | --- | --- |
| `light-default` | `studio` | `default` | — |
| `dark-default` | `studio` | `default` | `--dark` |
| `light-active` | `studio` | `active` | — |
| `narrow-library` | `library` | `default` | `--narrow` |

Полный запуск создаёт **40 PNG непосредственно из Qt**, без дорисовки и монтажа.
Каждый запуск получает новый каталог с UTC-временем и уникальным суффиксом:
старые файлы не могут выдать себя за новый результат. `index.html` показывает
снимки и позволяет открыть оригинал. `manifest.json` содержит точные команды,
набор данных, состояние, код возврата, длительность процесса, размер PNG,
разрешение и SHA-256 каждого успешного снимка, а также хеш исполняемого файла.

Диагностика Qt сохраняется полностью в manifest и отдельных файлах stderr/stdout.
В том числе сохраняются предупреждения шрифтов при старте; наличие сообщения
не скрывается и само по себе не считается неудачей снимка. Ненулевой код возврата,
тайм-аут, QML runtime error, изменение executable во время съёмки, отсутствующий или некорректный PNG делают соответствующий случай
неуспешным, а итоговый код скрипта — ненулевым. Проверяйте диагностику даже у
успешных кадров: сохранённая картинка не исключает предупреждений QML.

## Границы доказательств

Снимки подтверждают фактический рендеринг темы, данных, геометрии и выбранного
состояния на Linux. Они не подтверждают сами по себе клавиатурную навигацию,
работу screen reader, доступность после resize, виртуализацию большой модели
или поведение компонента в чужом приложении. Для этого нужны соответствующие
поведенческие тесты и отдельные измерения.

`elapsed_seconds` включает запуск приложения, загрузку QML и ожидание снимка.
Это длительность процесса, **не** измерение FPS или времени кадра. Доказательство
производительности должно указывать модель, число элементов, размер окна,
рендерер и метод измерения; успешный снимок большого набора данных не заменяет
такую проверку.

Lockups в Apple HIG особенно связаны с фокусируемыми элементами tvOS.
Здесь применим принцип цельной группы изображения и подписи; tvOS-параллакс
и дистанционная навигация не объявляются стандартом macOS. Apple явно помечает Lockups как tvOS-only; см. проверку платформ в HIG_LAYOUT_SOURCES.md.

Offscreen не проверяет оконный менеджер, нативные материалы macOS, vibrancy,
размытие за окном и системное сглаживание шрифтов. Windows и macOS требуют
отдельных запусков. Эта галерея проверяет компоненты проекта, а не наличие
изменений в исходниках qtbase и не полную замену интерфейса Obsidian.
