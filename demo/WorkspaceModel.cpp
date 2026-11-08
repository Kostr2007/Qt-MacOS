#include "WorkspaceModel.h"

#include <algorithm>
#include <functional>
#include <vector>

struct WorkspaceNode {
    QString id, title, subtitle, kind, tint;
    WorkspaceNode *parent = nullptr;
    bool folder = false;
    std::vector<std::unique_ptr<WorkspaceNode>> children;
};

namespace {
QVariant recordData(const QVariantMap &record, int column, int role)
{
    if (role == Qt::DisplayRole) {
        static const QStringList keys{QStringLiteral("title"), QStringLiteral("kind"), QStringLiteral("subtitle")};
        return column >= 0 && column < keys.size() ? record.value(keys.at(column)) : QVariant();
    }
    const auto roles = WorkspaceModel::workspaceRoles();
    const auto key = roles.value(role);
    return key.isEmpty() ? QVariant() : record.value(QString::fromUtf8(key));
}
QVariant heading(int section, Qt::Orientation orientation, int role)
{
    if (orientation != Qt::Horizontal || role != Qt::DisplayRole)
        return {};
    static const QStringList names{QStringLiteral("Name"), QStringLiteral("Kind"), QStringLiteral("Details")};
    return section >= 0 && section < names.size() ? names.at(section) : QVariant();
}
WorkspaceNode *add(WorkspaceNode *parent, const QString &id, const QString &title,
                   const QString &subtitle, const QString &kind, const QString &tint, bool folder = false)
{
    auto node = std::make_unique<WorkspaceNode>();
    node->id = id;
    node->title = title;
    node->subtitle = subtitle;
    node->kind = kind;
    node->tint = tint;
    node->folder = folder;
    node->parent = parent;
    auto *result = node.get();
    parent->children.push_back(std::move(node));
    return result;
}
}

WorkspaceEntriesModel::WorkspaceEntriesModel(WorkspaceModel *owner)
    : QAbstractItemModel(owner), m_owner(owner) {}

QModelIndex WorkspaceEntriesModel::index(int row, int column, const QModelIndex &parent) const
{
    return !parent.isValid() && row >= 0 && row < m_records.size() && column >= 0 && column < 3
        ? createIndex(row, column) : QModelIndex();
}
int WorkspaceEntriesModel::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_records.size(); }
int WorkspaceEntriesModel::columnCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : 3; }
QVariant WorkspaceEntriesModel::data(const QModelIndex &index, int role) const
{
    return index.isValid() && index.model() == this && index.row() < m_records.size()
        ? recordData(m_records.at(index.row()), index.column(), role) : QVariant();
}
QVariant WorkspaceEntriesModel::headerData(int section, Qt::Orientation orientation, int role) const { return heading(section, orientation, role); }
QHash<int, QByteArray> WorkspaceEntriesModel::roleNames() const { return WorkspaceModel::workspaceRoles(); }
QString WorkspaceEntriesModel::itemIdAt(int row) const
{
    return row >= 0 && row < m_records.size() ? m_records.at(row).value(QStringLiteral("itemId")).toString() : QString();
}
void WorkspaceEntriesModel::orderRecords()
{
    static const QStringList keys{QStringLiteral("title"), QStringLiteral("kind"), QStringLiteral("subtitle")};
    const auto key = keys.at(m_sortColumn);
    std::stable_sort(m_records.begin(), m_records.end(), [this, &key](const QVariantMap &a, const QVariantMap &b) {
        const int comparison = QString::compare(a.value(key).toString(), b.value(key).toString(), Qt::CaseInsensitive);
        return m_sortOrder == Qt::AscendingOrder ? comparison < 0 : comparison > 0;
    });
}
void WorkspaceEntriesModel::replace(QVector<QVariantMap> records)
{
    beginResetModel();
    m_records = std::move(records);
    orderRecords();
    endResetModel();
}
void WorkspaceEntriesModel::sort(int column, Qt::SortOrder order)
{
    if (column < 0 || column >= 3 || (order != Qt::AscendingOrder && order != Qt::DescendingOrder))
        return;
    beginResetModel();
    m_sortColumn = column;
    m_sortOrder = order;
    orderRecords();
    endResetModel();
    m_owner->changed();
}

WorkspaceModel::WorkspaceModel(QObject *parent)
    : QAbstractItemModel(parent), m_root(std::make_unique<WorkspaceNode>()), m_entries(new WorkspaceEntriesModel(this))
{
    loadFixture();
    rebuildEntries();
}
WorkspaceModel::~WorkspaceModel() = default;
QHash<int, QByteArray> WorkspaceModel::workspaceRoles()
{
    return {{Qt::DisplayRole, "display"}, {ItemIdRole, "itemId"}, {TitleRole, "title"}, {SubtitleRole, "subtitle"},
            {KindRole, "kind"}, {TintRole, "tint"}, {HasChildrenRole, "hasChildren"}};
}
QHash<int, QByteArray> WorkspaceModel::roleNames() const { return workspaceRoles(); }
QModelIndex WorkspaceModel::index(int row, int column, const QModelIndex &parent) const
{
    if (row < 0 || column < 0 || column >= 3 || (parent.isValid() && (parent.model() != this || parent.column() != 0)))
        return {};
    const auto *node = parent.isValid() ? static_cast<WorkspaceNode *>(parent.internalPointer()) : m_root.get();
    return row < int(node->children.size()) ? createIndex(row, column, node->children.at(row).get()) : QModelIndex();
}
QModelIndex WorkspaceModel::parent(const QModelIndex &index) const
{
    if (!index.isValid() || index.model() != this)
        return {};
    const auto *node = static_cast<WorkspaceNode *>(index.internalPointer());
    auto *parent = node->parent;
    if (!parent || parent == m_root.get())
        return {};
    const auto &siblings = parent->parent->children;
    for (int row = 0; row < int(siblings.size()); ++row)
        if (siblings.at(row).get() == parent)
            return createIndex(row, 0, parent);
    return {};
}
int WorkspaceModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid() && (parent.model() != this || parent.column() != 0))
        return 0;
    const auto *node = parent.isValid() ? static_cast<WorkspaceNode *>(parent.internalPointer()) : m_root.get();
    return int(node->children.size());
}
int WorkspaceModel::columnCount(const QModelIndex &) const { return 3; }
QVariant WorkspaceModel::data(const QModelIndex &index, int role) const
{
    return index.isValid() && index.model() == this
        ? recordData(record(static_cast<WorkspaceNode *>(index.internalPointer())), index.column(), role) : QVariant();
}
QVariant WorkspaceModel::headerData(int section, Qt::Orientation orientation, int role) const { return heading(section, orientation, role); }
int WorkspaceModel::entryCount() const { return m_entries->rowCount(); }
WorkspaceNode *WorkspaceModel::find(const QString &id) const
{
    if (id.isEmpty())
        return m_root.get();
    std::function<WorkspaceNode *(WorkspaceNode *)> visit = [&](WorkspaceNode *node) -> WorkspaceNode * {
        if (node->id == id)
            return node;
        for (const auto &child : node->children)
            if (auto *result = visit(child.get()))
                return result;
        return nullptr;
    };
    return visit(m_root.get());
}
QVariantMap WorkspaceModel::record(const WorkspaceNode *node) const
{
    if (!node || node == m_root.get())
        return {};
    return {{QStringLiteral("itemId"), node->id}, {QStringLiteral("title"), node->title},
            {QStringLiteral("subtitle"), node->subtitle}, {QStringLiteral("kind"), node->kind},
            {QStringLiteral("tint"), node->tint}, {QStringLiteral("hasChildren"), node->folder || !node->children.empty()},
            {QStringLiteral("parentId"), node->parent ? node->parent->id : QString()}};
}
QVariantMap WorkspaceModel::item(const QString &id) const { return record(find(id)); }
QModelIndex WorkspaceModel::indexForId(const QString &id) const
{
    auto *node = find(id);
    if (!node || node == m_root.get())
        return {};
    const auto &siblings = node->parent->children;
    for (int row = 0; row < int(siblings.size()); ++row)
        if (siblings.at(row).get() == node)
            return createIndex(row, 0, node);
    return {};
}
QString WorkspaceModel::itemIdForIndex(const QModelIndex &index) const
{
    return index.isValid() && index.model() == this
        ? static_cast<WorkspaceNode *>(index.internalPointer())->id : QString();
}
QVariantList WorkspaceModel::childrenFor(const QString &parentId) const
{
    QVariantList result;
    const auto *node = find(parentId);
    if (node)
        for (const auto &child : node->children)
            result.push_back(record(child.get()));
    return result;
}
QVariantList WorkspaceModel::pathFor(const QString &id) const
{
    QVariantList result;
    auto *node = find(id);
    while (node && node != m_root.get()) {
        result.prepend(record(node));
        node = node->parent;
    }
    return result;
}
void WorkspaceModel::setSelectedId(const QString &id)
{
    QString valid = id.isEmpty() || !find(id) ? QString() : id;
    if (!valid.isEmpty()) {
        const auto *node = find(valid);
        if (!node->folder && node->children.empty()) {
            const bool visible = std::any_of(m_entries->m_records.cbegin(), m_entries->m_records.cend(), [&valid](const QVariantMap &record) {
                return record.value(QStringLiteral("itemId")).toString() == valid;
            });
            if (!visible)
                valid.clear();
        }
    }
    if (valid == m_selectedId)
        return;
    m_selectedId = valid;
    emit selectedIdChanged();
}
void WorkspaceModel::validateSelection()
{
    if (m_selectedId.isEmpty())
        return;
    const auto *node = find(m_selectedId);
    bool visible = node && (node->folder || !node->children.empty());
    if (node && !visible)
        for (const auto &record : m_entries->m_records)
            if (record.value(QStringLiteral("itemId")).toString() == m_selectedId) {
                visible = true;
                break;
            }
    if (!visible) {
        m_selectedId.clear();
        emit selectedIdChanged();
    }
}
void WorkspaceModel::rebuildEntries()
{
    QVector<QVariantMap> records;
    std::function<void(const WorkspaceNode *)> visit = [&](const WorkspaceNode *node) {
        for (const auto &child : node->children) {
            if (!child->folder && child->children.empty()) {
                if (m_filter.isEmpty() || child->title.contains(m_filter, Qt::CaseInsensitive)
                    || child->subtitle.contains(m_filter, Qt::CaseInsensitive) || child->kind.contains(m_filter, Qt::CaseInsensitive))
                    records.push_back(record(child.get()));
            }
            visit(child.get());
        }
    };
    visit(m_root.get());
    const int previousCount = entryCount();
    m_entries->replace(std::move(records));
    if (previousCount != entryCount())
        emit entryCountChanged();
    validateSelection();
}
void WorkspaceModel::changed() { ++m_revision; emit revisionChanged(); }
void WorkspaceModel::setFilter(const QString &filter)
{
    if (m_filter == filter)
        return;
    m_filter = filter;
    rebuildEntries();
    emit filterChanged();
    changed();
}
void WorkspaceModel::setDataset(const QString &dataset)
{
    if ((dataset != QStringLiteral("studio") && dataset != QStringLiteral("library")) || m_dataset == dataset)
        return;
    beginResetModel();
    m_dataset = dataset;
    loadFixture();
    endResetModel();
    rebuildEntries();
    emit datasetChanged();
    changed();
}
QString WorkspaceModel::appendItem(const QString &parentId, const QString &title)
{
    auto *parent = find(parentId);
    if (!parent || (parent != m_root.get() && !parent->folder) || title.trimmed().isEmpty())
        return {};
    const QString id = QStringLiteral("item-%1").arg(m_nextId++);
    beginResetModel();
    add(parent, id, title.trimmed(), QStringLiteral("Just added · Draft"), QStringLiteral("Document"), QStringLiteral("#0a84ff"));
    endResetModel();
    rebuildEntries();
    changed();
    return id;
}
bool WorkspaceModel::renameItem(const QString &id, const QString &title)
{
    auto *node = find(id);
    if (!node || node == m_root.get() || title.trimmed().isEmpty())
        return false;
    if (node->title == title.trimmed())
        return true;
    beginResetModel();
    node->title = title.trimmed();
    endResetModel();
    rebuildEntries();
    changed();
    return true;
}
bool WorkspaceModel::removeItem(const QString &id)
{
    auto *node = find(id);
    if (!node || node == m_root.get())
        return false;
    auto &siblings = node->parent->children;
    beginResetModel();
    siblings.erase(std::find_if(siblings.begin(), siblings.end(), [node](const auto &candidate) { return candidate.get() == node; }));
    endResetModel();
    rebuildEntries();
    changed();
    return true;
}
void WorkspaceModel::generateItems(int count)
{
    count = std::clamp(count, 0, 100000);
    beginResetModel();
    m_root = std::make_unique<WorkspaceNode>();
    auto *folder = add(m_root.get(), QStringLiteral("generated"), QStringLiteral("Performance collection"), QStringLiteral("Generated assets"), QStringLiteral("Folder"), QStringLiteral("#0a84ff"), true);
    for (int i = 0; i < count; ++i)
        add(folder, QStringLiteral("generated-%1").arg(i), QStringLiteral("Asset %1").arg(i + 1, 5, 10, QLatin1Char('0')),
            QStringLiteral("%1 KB · Ready to review").arg(24 + i % 2048),
            i % 3 ? QStringLiteral("Image") : QStringLiteral("Scene"), i % 2 ? QStringLiteral("#bf5af2") : QStringLiteral("#30d158"));
    endResetModel();
    rebuildEntries();
    changed();
}
void WorkspaceModel::sortEntries(int column, bool ascending) { m_entries->sort(column, ascending ? Qt::AscendingOrder : Qt::DescendingOrder); }
void WorkspaceModel::loadFixture()
{
    m_root = std::make_unique<WorkspaceNode>();
    if (m_dataset == QStringLiteral("library")) {
        auto *photos = add(m_root.get(), QStringLiteral("photos"), QStringLiteral("Photography"), QStringLiteral("Curated collections"), QStringLiteral("Folder"), QStringLiteral("#ff9f0a"), true);
        auto *coast = add(photos, QStringLiteral("coast"), QStringLiteral("Coastal studies"), QStringLiteral("Summer field notes"), QStringLiteral("Folder"), QStringLiteral("#0a84ff"), true);
        add(coast, QStringLiteral("coast-dawn"), QStringLiteral("First light"), QStringLiteral("3024 × 2016 · 4.2 MB"), QStringLiteral("Image"), QStringLiteral("#64d2ff"));
        add(coast, QStringLiteral("coast-cliff"), QStringLiteral("Cliff walk"), QStringLiteral("4032 × 3024 · 6.8 MB"), QStringLiteral("Image"), QStringLiteral("#30d158"));
        add(photos, QStringLiteral("city-night"), QStringLiteral("City after dark"), QStringLiteral("2400 × 1600 · 3.1 MB"), QStringLiteral("Image"), QStringLiteral("#bf5af2"));
        auto *documents = add(m_root.get(), QStringLiteral("documents"), QStringLiteral("Documents"), QStringLiteral("Notes and publications"), QStringLiteral("Folder"), QStringLiteral("#0a84ff"), true);
        add(documents, QStringLiteral("field-notes"), QStringLiteral("Field notes"), QStringLiteral("12 pages · Edited today"), QStringLiteral("Document"), QStringLiteral("#ff9f0a"));
        add(documents, QStringLiteral("reading-list"), QStringLiteral("Reading list"), QStringLiteral("8 references · Updated yesterday"), QStringLiteral("Document"), QStringLiteral("#ff453a"));
        auto *audio = add(m_root.get(), QStringLiteral("audio"), QStringLiteral("Audio"), QStringLiteral("Recordings and soundscapes"), QStringLiteral("Folder"), QStringLiteral("#ff375f"), true);
        add(audio, QStringLiteral("rain-recording"), QStringLiteral("Rain on the roof"), QStringLiteral("03:42 · Stereo"), QStringLiteral("Audio"), QStringLiteral("#5e5ce6"));
        add(audio, QStringLiteral("ocean-recording"), QStringLiteral("Ocean breeze"), QStringLiteral("05:18 · Stereo"), QStringLiteral("Audio"), QStringLiteral("#64d2ff"));
        return;
    }
    auto *orbit = add(m_root.get(), QStringLiteral("project-orbit"), QStringLiteral("Project Orbit"), QStringLiteral("World building · In progress"), QStringLiteral("Project"), QStringLiteral("#0a84ff"), true);
    auto *assets = add(orbit, QStringLiteral("assets"), QStringLiteral("Assets"), QStringLiteral("Reusable project resources"), QStringLiteral("Folder"), QStringLiteral("#bf5af2"), true);
    auto *textures = add(assets, QStringLiteral("textures"), QStringLiteral("Textures"), QStringLiteral("Surfaces and materials"), QStringLiteral("Folder"), QStringLiteral("#ff9f0a"), true);
    add(textures, QStringLiteral("texture-basalt"), QStringLiteral("Basalt surface"), QStringLiteral("2048 × 2048 · 3.8 MB"), QStringLiteral("Texture"), QStringLiteral("#8e8e93"));
    add(textures, QStringLiteral("texture-moss"), QStringLiteral("Forest moss"), QStringLiteral("2048 × 2048 · 2.4 MB"), QStringLiteral("Texture"), QStringLiteral("#30d158"));
    add(assets, QStringLiteral("asset-compass"), QStringLiteral("Explorer compass"), QStringLiteral("Vector artwork · 42 KB"), QStringLiteral("Illustration"), QStringLiteral("#ff9f0a"));
    add(assets, QStringLiteral("asset-beacon"), QStringLiteral("Signal beacon"), QStringLiteral("3D model · 1.8 MB"), QStringLiteral("Model"), QStringLiteral("#ff453a"));
    auto *scenes = add(orbit, QStringLiteral("scenes"), QStringLiteral("Scenes"), QStringLiteral("Playable environments"), QStringLiteral("Folder"), QStringLiteral("#30d158"), true);
    add(scenes, QStringLiteral("scene-arrival"), QStringLiteral("Arrival valley"), QStringLiteral("Scene 01 · Ready to review"), QStringLiteral("Scene"), QStringLiteral("#64d2ff"));
    add(scenes, QStringLiteral("scene-observatory"), QStringLiteral("The observatory"), QStringLiteral("Scene 02 · In progress"), QStringLiteral("Scene"), QStringLiteral("#bf5af2"));
    add(orbit, QStringLiteral("orbit-brief"), QStringLiteral("Creative brief"), QStringLiteral("6 pages · Updated today"), QStringLiteral("Document"), QStringLiteral("#0a84ff"));
    auto *atlas = add(m_root.get(), QStringLiteral("project-atlas"), QStringLiteral("Project Atlas"), QStringLiteral("Navigation studies · Planning"), QStringLiteral("Project"), QStringLiteral("#ff9f0a"), true);
    add(atlas, QStringLiteral("atlas-map"), QStringLiteral("Archipelago map"), QStringLiteral("4096 × 3072 · 8.4 MB"), QStringLiteral("Illustration"), QStringLiteral("#30d158"));
    add(atlas, QStringLiteral("atlas-route"), QStringLiteral("Route prototypes"), QStringLiteral("4 variations · Draft"), QStringLiteral("Document"), QStringLiteral("#ff9f0a"));
    auto *shared = add(m_root.get(), QStringLiteral("shared"), QStringLiteral("Shared library"), QStringLiteral("Available to every project"), QStringLiteral("Folder"), QStringLiteral("#5e5ce6"), true);
    add(shared, QStringLiteral("shared-palette"), QStringLiteral("Color explorations"), QStringLiteral("12 swatches · Approved"), QStringLiteral("Palette"), QStringLiteral("#ff375f"));
    add(shared, QStringLiteral("shared-sound"), QStringLiteral("Ambient horizon"), QStringLiteral("02:36 · Stereo"), QStringLiteral("Audio"), QStringLiteral("#5e5ce6"));
    add(shared, QStringLiteral("shared-guide"), QStringLiteral("Studio guidelines"), QStringLiteral("18 pages · Version 2"), QStringLiteral("Document"), QStringLiteral("#0a84ff"));
}
