#include "WorkspaceModel.h"

#include <QAbstractItemModelTester>
#include <QPersistentModelIndex>
#include <QSignalSpy>
#include <QtTest>

class WorkspaceModelTest : public QObject
{
    Q_OBJECT
private slots:
    void hierarchyAndSharedRecords();
    void mutationAndSelection();
    void filteringAndSorting();
    void datasetsAndStress();
};

void WorkspaceModelTest::hierarchyAndSharedRecords()
{
    WorkspaceModel model;
    QCOMPARE(model.entries()->roleNames().value(Qt::DisplayRole), QByteArray("display"));
    QAbstractItemModelTester treeTester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
    QAbstractItemModelTester flatTester(model.entries(), QAbstractItemModelTester::FailureReportingMode::QtTest);
    QCOMPARE(model.rowCount(), 3);
    QCOMPARE(model.columnCount(), 3);
    const auto orbit = model.index(0, 0);
    QCOMPARE(model.itemIdForIndex(orbit), QStringLiteral("project-orbit"));
    QCOMPARE(model.data(orbit, WorkspaceModel::TitleRole).toString(), QStringLiteral("Project Orbit"));
    QCOMPARE(model.data(model.index(0, 1), Qt::DisplayRole).toString(), QStringLiteral("Project"));
    QCOMPARE(model.childrenFor("project-orbit").size(), 3);
    QVERIFY(!model.parent(orbit).isValid());
    const auto basalt = model.indexForId("texture-basalt");
    QVERIFY(basalt.isValid());
    QCOMPARE(model.itemIdForIndex(model.parent(basalt)), QStringLiteral("textures"));
    QCOMPARE(model.pathFor("texture-basalt").size(), 4);
    QCOMPARE(model.pathFor("texture-basalt").first().toMap().value("itemId").toString(), QStringLiteral("project-orbit"));
    QCOMPARE(model.item("texture-basalt").value("parentId").toString(), QStringLiteral("textures"));
    QCOMPARE(model.entries()->rowCount(), 12);
    QVERIFY(!model.index(-1, 0).isValid());
    QVERIFY(!model.index(0, 3).isValid());
    QVERIFY(!model.index(0, 0, model.index(0, 1)).isValid());
    QCOMPARE(model.rowCount(model.index(0, 1)), 0);
    QVERIFY(model.childrenFor("missing").isEmpty());
    QVERIFY(model.pathFor("missing").isEmpty());
    QVERIFY(model.item("missing").isEmpty());
    QVERIFY(!model.indexForId("missing").isValid());
    QVERIFY(model.itemIdForIndex(model.entries()->index(0, 0)).isEmpty());
    const auto *flat = qobject_cast<WorkspaceEntriesModel *>(model.entries());
    QVERIFY(flat);
    QVERIFY(flat->itemIdAt(-1).isEmpty());
    for (int row = 0; row < flat->rowCount(); ++row) {
        const auto index = flat->index(row, 0);
        const auto id = flat->itemIdAt(row);
        QCOMPARE(flat->data(index, WorkspaceModel::TitleRole), model.item(id).value("title"));
        QCOMPARE(flat->data(index, WorkspaceModel::HasChildrenRole).toBool(), false);
    }
}

void WorkspaceModelTest::mutationAndSelection()
{
    WorkspaceModel model;
    QAbstractItemModelTester treeTester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
    QAbstractItemModelTester flatTester(model.entries(), QAbstractItemModelTester::FailureReportingMode::QtTest);
    QSignalSpy selectionSpy(&model, &WorkspaceModel::selectedIdChanged);
    QSignalSpy revisionSpy(&model, &WorkspaceModel::revisionChanged);
    QSignalSpy countSpy(&model, &WorkspaceModel::entryCountChanged);
    model.setSelectedId("texture-basalt");
    QCOMPARE(selectionSpy.size(), 1);
    const QPersistentModelIndex previousIndex(model.indexForId("texture-basalt"));
    const auto newId = model.appendItem("assets", "  New material  ");
    QVERIFY(!newId.isEmpty());
    QCOMPARE(model.entryCount(), 13);
    QCOMPARE(model.item(newId).value("title").toString(), QStringLiteral("New material"));
    QCOMPARE(model.selectedId(), QStringLiteral("texture-basalt"));
    QVERIFY(!previousIndex.isValid()); // A reset deliberately invalidates indexes; selection uses a stable ID.
    QVERIFY(model.renameItem("texture-basalt", "Basalt revised"));
    QCOMPARE(model.item("texture-basalt").value("title").toString(), QStringLiteral("Basalt revised"));
    QCOMPARE(model.selectedId(), QStringLiteral("texture-basalt"));
    QCOMPARE(selectionSpy.size(), 1);
    QVERIFY(model.removeItem("textures"));
    QCOMPARE(model.selectedId(), QString());
    QCOMPARE(model.entryCount(), 11);
    QCOMPARE(selectionSpy.size(), 2);
    QCOMPARE(revisionSpy.size(), 3);
    QCOMPARE(countSpy.size(), 2);
    QVERIFY(model.item("texture-basalt").isEmpty());
    QVERIFY(!model.removeItem("textures"));
    QVERIFY(!model.removeItem(""));
    QVERIFY(!model.renameItem("missing", "Title"));
    QVERIFY(!model.renameItem(newId, "   "));
    QVERIFY(model.appendItem("missing", "Title").isEmpty());
    QVERIFY(model.appendItem(newId, "Title").isEmpty());
    QVERIFY(model.appendItem("assets", "  ").isEmpty());
    model.setSelectedId("not-a-real-id");
    QCOMPARE(model.selectedId(), QString());
}

void WorkspaceModelTest::filteringAndSorting()
{
    WorkspaceModel model;
    QAbstractItemModelTester treeTester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
    QAbstractItemModelTester flatTester(model.entries(), QAbstractItemModelTester::FailureReportingMode::QtTest);
    auto *flat = qobject_cast<WorkspaceEntriesModel *>(model.entries());
    model.setSelectedId("texture-basalt");
    model.sortEntries(0, false);
    QCOMPARE(model.selectedId(), QStringLiteral("texture-basalt"));
    QCOMPARE(flat->itemIdAt(0), QStringLiteral("scene-observatory"));
    flat->sort(0, Qt::AscendingOrder);
    QCOMPARE(flat->itemIdAt(0), QStringLiteral("shared-sound"));
    for (int row = 1; row < flat->rowCount(); ++row) {
        const auto a = flat->data(flat->index(row - 1, 0), WorkspaceModel::TitleRole).toString();
        const auto b = flat->data(flat->index(row, 0), WorkspaceModel::TitleRole).toString();
        QVERIFY(QString::compare(a, b, Qt::CaseInsensitive) <= 0);
    }
    model.setFilter("BASALT");
    QCOMPARE(model.entryCount(), 1);
    QCOMPARE(model.selectedId(), QStringLiteral("texture-basalt"));
    QCOMPARE(model.rowCount(), 3); // Filtering the projection does not erase the browsable hierarchy.
    QVERIFY(model.renameItem("texture-basalt", "Dark basalt"));
    QCOMPARE(model.selectedId(), QStringLiteral("texture-basalt"));
    model.setFilter("Forest");
    QCOMPARE(model.entryCount(), 1);
    QCOMPARE(model.selectedId(), QString());
    model.setSelectedId("texture-basalt");
    QCOMPARE(model.selectedId(), QString());
    model.setFilter("");
    QCOMPARE(model.entryCount(), 12);
    model.setSelectedId("scene-arrival");
    QVERIFY(model.renameItem("scene-arrival", "Landing valley"));
    model.setFilter("Landing");
    QCOMPARE(model.selectedId(), QStringLiteral("scene-arrival"));
    QVERIFY(model.renameItem("scene-arrival", "Northern valley"));
    QCOMPARE(model.selectedId(), QString());
    QCOMPARE(model.entryCount(), 0);
    flat->sort(-1, Qt::AscendingOrder); // Invalid user input leaves the model intact.
}

void WorkspaceModelTest::datasetsAndStress()
{
    WorkspaceModel model;
    QAbstractItemModelTester treeTester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
    QAbstractItemModelTester flatTester(model.entries(), QAbstractItemModelTester::FailureReportingMode::QtTest);
    model.setSelectedId("texture-basalt");
    model.setDataset("library");
    QCOMPARE(model.dataset(), QStringLiteral("library"));
    QCOMPARE(model.selectedId(), QString());
    QCOMPARE(model.rowCount(), 3);
    QCOMPARE(model.entryCount(), 7);
    QCOMPARE(model.pathFor("coast-dawn").size(), 3);
    model.setDataset("unknown");
    QCOMPARE(model.dataset(), QStringLiteral("library"));
    model.setDataset("studio");
    QCOMPARE(model.entryCount(), 12);
    model.generateItems(10000);
    QCOMPARE(model.rowCount(), 1);
    QCOMPARE(model.rowCount(model.index(0, 0)), 10000);
    QCOMPARE(model.entryCount(), 10000);
    model.setSelectedId("generated-9999");
    model.sortEntries(0, false);
    QCOMPARE(model.selectedId(), QStringLiteral("generated-9999"));
    QCOMPARE(model.entries()->data(model.entries()->index(0, 0), WorkspaceModel::ItemIdRole).toString(), QStringLiteral("generated-9999"));
    model.setFilter("Asset 10000");
    QCOMPARE(model.entryCount(), 1);
    QCOMPARE(model.selectedId(), QStringLiteral("generated-9999"));
    model.generateItems(-3);
    QCOMPARE(model.entryCount(), 0);
    QCOMPARE(model.selectedId(), QString());
}

QTEST_GUILESS_MAIN(WorkspaceModelTest)
#include "test_workspace_model.moc"
