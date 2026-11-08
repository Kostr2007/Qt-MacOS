import QtQuick
import QtTest
import Qt.labs.qmlmodels
import QtMacOS

Item {
    width: 840; height: 520
    property string selectedList: ""
    property string selectedTable: ""
    ListModel {
        id: entries
        ListElement { itemId: "a"; title: "Harbor"; subtitle: "Coastal level"; kind: "Level"; tint: "#428bd0" }
        ListElement { itemId: "b"; title: "Forest"; subtitle: "Woodland level"; kind: "Level"; tint: "#619b64" }
        ListElement { itemId: "c"; title: "Castle"; subtitle: "Fortress level"; kind: "Level"; tint: "#9971aa" }
    }
    TableModel {
        id: records
        TableModelColumn { display: "title" }
        TableModelColumn { display: "kind" }
        TableModelColumn { display: "details" }
        rows: [
            {title: "Harbor", kind: "Level", details: "Coastal level"},
            {title: "Forest", kind: "Level", details: "Woodland level"},
            {title: "Castle", kind: "Level", details: "Fortress level"}
        ]
    }
    MacListView {
        id: list; x: 0; y: 0; width: 250; height: 250
        model: entries; selectedId: selectedList
        onSelectionRequested: itemId => selectedList = itemId
    }
    MacTableView {
        id: table; x: 270; y: 0; width: 560; height: 250
        model: records; selectedId: selectedTable
        rowIdProvider: row => String(row)
        onSelectionRequested: itemId => selectedTable = itemId
    }
    SignalSpy { id: listSpy; target: list; signalName: "selectionRequested" }
    SignalSpy { id: tableSpy; target: table; signalName: "selectionRequested" }
    SignalSpy { id: sortSpy; target: table; signalName: "sortRequested" }
    TestCase {
        name: "MacDataViews"
        when: windowShown
        function init() {
            selectedList = ""; selectedTable = "";
            listSpy.clear(); tableSpy.clear(); sortSpy.clear();
            table.sortColumn = -1;
            table.columnWidths = [260, 140, 220];
        }
        function cleanup() {
            if (entries.count > 3) entries.remove(3, entries.count - 3);
            if (records.rowCount > 3) records.rows = [
                {title: "Harbor", kind: "Level", details: "Coastal level"},
                {title: "Forest", kind: "Level", details: "Woodland level"},
                {title: "Castle", kind: "Level", details: "Fortress level"}
            ];
        }
        function test_listKeyboardAndControlledSelection() {
            compare(list.count, 3);
            list.forceActiveFocus();
            keyClick(Qt.Key_Home); compare(selectedList, "a");
            keyClick(Qt.Key_Down); compare(selectedList, "b");
            keyClick(Qt.Key_End); compare(selectedList, "c");
            keyClick(Qt.Key_Up); compare(selectedList, "b");
            selectedList = "a";
            compare(list.selectedId, "a");
            keyClick(Qt.Key_Down); compare(selectedList, "b");
            compare(listSpy.count, 5);
        }
        function test_listPointerRequestsStableId() {
            mouseClick(list, 90, 75);
            compare(listSpy.count, 1);
            compare(listSpy.signalArguments[0][0], "b");
            selectedList = "c";
            compare(list.selectedId, "c");
        }
        function test_tableHeaderSortAndResize() {
            const heading = findChild(table, "macTableHeading0");
            verify(heading);
            mouseClick(heading, 40, 15);
            compare(sortSpy.count, 1);
            compare(sortSpy.signalArguments[0][0], 0);
            compare(sortSpy.signalArguments[0][1], true);
            mouseClick(heading, 40, 15);
            compare(sortSpy.signalArguments[1][1], false);
            const content = findChild(table, "macTableContent");
            tryVerify(() => content.itemAtCell(Qt.point(0, 0)) !== null);
            compare(content.itemAtCell(Qt.point(0, 0)).width, 260);
            table.resizeColumn(0, 310);
            tryCompare(heading, "width", 310);
            tryCompare(content.itemAtCell(Qt.point(0, 0)), "width", 310);
            table.resizeColumn(0, 1);
            compare(table.columnWidth(0), 72);
            table.resizeColumn(-1, 300);
            compare(table.columnWidths.length, 3);
        }
        function test_tableSelectionKeyboardAndModelEdits() {
            compare(table.rowCount, 3);
            table.forceActiveFocus();
            keyClick(Qt.Key_Home); compare(selectedTable, "0");
            keyClick(Qt.Key_End); compare(selectedTable, "2");
            keyClick(Qt.Key_Up); compare(selectedTable, "1");
            selectedTable = "0";
            keyClick(Qt.Key_Down); compare(selectedTable, "1");
            const content = findChild(table, "macTableContent");
            records.setRow(0, {title: "Harbor edited", kind: "Level", details: "Updated"});
            const firstCell = content.itemAtCell(Qt.point(0, 0));
            tryCompare(firstCell.children[0], "text", "Harbor edited");
            records.setRow(0, {title: "Harbor", kind: "Level", details: "Coastal level"});
        }
        function test_largeListAndTableKeepVirtualizedDelegates() {
            for (let i = 3; i < 500; ++i)
                entries.append({itemId: "item" + i, title: "Level " + i,
                                subtitle: "Virtualized entry", kind: "Level", tint: "#428bd0"});
            const content = findChild(list, "macListContent");
            tryCompare(list, "count", 500);
            list.forceActiveFocus();
            keyClick(Qt.Key_End);
            compare(selectedList, "item499");
            verify(content.contentItem.children.length < 100);
            entries.remove(3, 497);

            const manyRows = [];
            for (let i = 0; i < 500; ++i)
                manyRows.push({title: "Level " + i, kind: "Level", details: "Virtualized entry"});
            const originalRows = JSON.parse(JSON.stringify(records.rows));
            records.rows = manyRows;
            tryCompare(table, "rowCount", 500);
            table.forceActiveFocus();
            keyClick(Qt.Key_End);
            compare(selectedTable, "499");
            const tableContent = findChild(table, "macTableContent");
            verify(tableContent.contentItem.children.length < 100);
            records.rows = originalRows;
        }
        function test_tableHorizontalScrollKeepsHeaderAligned() {
            const content = findChild(table, "macTableContent");
            const heading = findChild(table, "macTableHeading1").parent;
            table.resizeColumn(0, 400);
            content.contentX = 80;
            compare(heading.x, 320);
            content.contentX = 0;
        }
    }
}
