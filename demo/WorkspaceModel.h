#pragma once

#include <QAbstractItemModel>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>
#include <memory>

struct WorkspaceNode;
class WorkspaceModel;

// A single, sortable projection shared by the collection, list and table views.
class WorkspaceEntriesModel final : public QAbstractItemModel
{
    Q_OBJECT
public:
    explicit WorkspaceEntriesModel(WorkspaceModel *owner);
    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;
    QModelIndex parent(const QModelIndex &) const override { return {}; }
    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void sort(int column, Qt::SortOrder order = Qt::AscendingOrder) override;
    Q_INVOKABLE QString itemIdAt(int row) const;

private:
    friend class WorkspaceModel;
    void replace(QVector<QVariantMap> records);
    void orderRecords();
    WorkspaceModel *m_owner;
    QVector<QVariantMap> m_records;
    int m_sortColumn = 0;
    Qt::SortOrder m_sortOrder = Qt::AscendingOrder;
};

class WorkspaceModel : public QAbstractItemModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QAbstractItemModel *entries READ entries CONSTANT)
    Q_PROPERTY(QString selectedId READ selectedId WRITE setSelectedId NOTIFY selectedIdChanged)
    Q_PROPERTY(QString dataset READ dataset WRITE setDataset NOTIFY datasetChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)
    Q_PROPERTY(int entryCount READ entryCount NOTIFY entryCountChanged)
public:
    enum Role { ItemIdRole = Qt::UserRole + 1, TitleRole, SubtitleRole, KindRole, TintRole, HasChildrenRole };
    Q_ENUM(Role)
    explicit WorkspaceModel(QObject *parent = nullptr);
    ~WorkspaceModel() override;
    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;
    QModelIndex parent(const QModelIndex &index) const override;
    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    QAbstractItemModel *entries() const { return m_entries; }
    QString selectedId() const { return m_selectedId; }
    QString dataset() const { return m_dataset; }
    QString filter() const { return m_filter; }
    int revision() const { return m_revision; }
    int entryCount() const;
    void setSelectedId(const QString &id);
    void setDataset(const QString &dataset);
    void setFilter(const QString &filter);
    Q_INVOKABLE QVariantList childrenFor(const QString &parentId = {}) const;
    Q_INVOKABLE QVariantList pathFor(const QString &id) const;
    Q_INVOKABLE QVariantMap item(const QString &id) const;
    Q_INVOKABLE QString entryIdAt(int row) const { return m_entries->itemIdAt(row); }
    Q_INVOKABLE QModelIndex indexForId(const QString &id) const;
    Q_INVOKABLE QString itemIdForIndex(const QModelIndex &index) const;
    Q_INVOKABLE QString appendItem(const QString &parentId, const QString &title);
    Q_INVOKABLE bool renameItem(const QString &id, const QString &title);
    Q_INVOKABLE bool removeItem(const QString &id);
    Q_INVOKABLE void generateItems(int count);
    Q_INVOKABLE void sortEntries(int column, bool ascending = true);
    static QHash<int, QByteArray> workspaceRoles();

signals:
    void selectedIdChanged();
    void datasetChanged();
    void filterChanged();
    void revisionChanged();
    void entryCountChanged();

private:
    friend class WorkspaceEntriesModel;
    WorkspaceNode *find(const QString &id) const;
    QVariantMap record(const WorkspaceNode *node) const;
    void rebuildEntries();
    void changed();
    void validateSelection();
    void loadFixture();
    std::unique_ptr<WorkspaceNode> m_root;
    WorkspaceEntriesModel *m_entries;
    QString m_selectedId;
    QString m_dataset = QStringLiteral("studio");
    QString m_filter;
    int m_revision = 0;
    quint64 m_nextId = 1;
};
