import QtQuick
import QtTest
import QtMacOS

Item {
    id: fixture
    width: 800
    height: 500
    property string selection: ""
    ListModel { id: entries }
    MacCollectionView {
        id: collection
        width: 640
        height: 330
        model: entries
        selectedId: fixture.selection
        onSelectionRequested: (itemId) => fixture.selection = itemId
    }
    MacLockup {
        id: lockup
        y: 335
        width: 160
        height: 160
        itemId: "standalone"
        title: "Archive"
        subtitle: "12 items"
    }
    SignalSpy { id: requestSpy; target: collection; signalName: "selectionRequested" }
    SignalSpy { id: openSpy; target: collection; signalName: "activated" }
    SignalSpy { id: actionSpy; target: lockup; signalName: "activated" }
    TestCase {
        name: "MacCollections"
        when: windowShown
        function row(id, title) {
            return { itemId: id, title: title, subtitle: "2 items", kind: "folder", tint: "#52b9ed" }
        }
        function init() {
            collection.width = 640
            fixture.selection = ""
            entries.clear()
            entries.append(row("alpha", "Projects"))
            entries.append(row("beta", "Pictures"))
            entries.append(row("gamma", "Archive"))
            lockup.enabled = true
            requestSpy.clear(); openSpy.clear(); actionSpy.clear()
            tryCompare(collection, "itemCount", 3)
        }
        function test_cardIsOneKeyboardAndPointerAction() {
            mouseClick(lockup)
            compare(actionSpy.count, 1)
            lockup.forceActiveFocus()
            keyClick(Qt.Key_Space)
            compare(actionSpy.count, 2)
            lockup.enabled = false
            mouseClick(lockup)
            compare(actionSpy.count, 2)
        }
        function test_keyboardUsesStableIdsAfterModelChanges() {
            fixture.selection = "beta"
            entries.insert(0, row("new", "New folder"))
            entries.move(2, 3, 1)
            compare(collection.selectedId, "beta")
            collection.forceActiveFocus()
            keyClick(Qt.Key_Left)
            compare(fixture.selection, "gamma")
            keyClick(Qt.Key_Home)
            compare(fixture.selection, "new")
            keyClick(Qt.Key_End)
            compare(fixture.selection, "beta")
            keyClick(Qt.Key_Return)
            compare(openSpy.count, 1)
            compare(openSpy.signalArguments[0][0], "beta")
            fixture.selection = "alpha"
            compare(collection.selectedId, "alpha")
        }
        function test_pointerAndResponsiveRows() {
            mouseClick(collection, 80, 80)
            compare(fixture.selection, "alpha")
            compare(collection.columnCount, 4)
            collection.width = 330
            compare(collection.columnCount, 2)
            collection.forceActiveFocus()
            keyClick(Qt.Key_Down)
            compare(fixture.selection, "gamma")
        }
        function test_emptyModelKeepsExternalSelection() {
            fixture.selection = "beta"
            entries.clear()
            tryCompare(collection, "itemCount", 0)
            compare(collection.selectedId, "beta")
            verify(findChild(collection, "collectionEmptyLabel").visible)
            collection.forceActiveFocus()
            keyClick(Qt.Key_Home); keyClick(Qt.Key_End); keyClick(Qt.Key_Right)
            compare(requestSpy.count, 0)
            entries.append(row("beta", "Restored"))
            tryCompare(collection, "itemCount", 1)
            keyClick(Qt.Key_Return)
            compare(openSpy.signalArguments[0][0], "beta")
        }
    }
}
