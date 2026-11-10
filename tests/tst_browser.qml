import QtQuick
import QtTest
import QtMacOS
import "../demo" as Demo

Item {
    id: root
    width: 900; height: 600
    Demo.FileBrowser { id: browser; anchors.fill: parent }
    Component { id: freshBrowser; Demo.FileBrowser { width: 900; height: 600 } }
    TestCase {
        name: "FileBrowser"
        when: windowShown
        function init() {
            browser.query = ""; browser.category = "Documents"
            browser.ascending = true; browser.gridMode = false; browser.selectedName = ""
        }
        function test_filterAndEmptyState() {
            compare(browser.resultCount, 9)
            browser.query = "PNG"; compare(browser.resultCount, 2)
            browser.query = "НЕСУЩЕСТВУЮЩИЙ"; compare(browser.resultCount, 0)
            browser.query = "NSRA"; compare(browser.resultCount, 1)
        }
        function test_initialSelectionIsEmpty() {
            const fresh = createTemporaryObject(freshBrowser, root)
            verify(fresh !== null)
            wait(0)
            compare(fresh.resultCount, 9)
            compare(fresh.selectedName, "")
            fresh.gridMode = true
            wait(0)
            compare(fresh.selectedName, "")
        }
        function test_sort() {
            const first = browser.visibleFiles[0].name
            browser.ascending = false
            compare(browser.visibleFiles[browser.resultCount - 1].name, first)
        }
        function test_categoryFilter() {
            browser.category = "Downloads"; compare(browser.resultCount, 3)
        }
        function test_listKeyboardSelection() {
            const list = findChild(browser, "fileList")
            list.forceActiveFocus(); browser.selectIndex(0)
            keyClick(Qt.Key_Down)
            compare(list.currentIndex, 1)
            compare(browser.selectedName, browser.visibleFiles[1].name)
        }
        function test_gridNavigation() {
            browser.gridMode = true
            const grid = findChild(browser, "fileGrid")
            grid.forceActiveFocus(); browser.selectIndex(0)
            keyClick(Qt.Key_Right)
            compare(grid.currentIndex, 1)
            compare(browser.selectedName, browser.visibleFiles[1].name)
        }
        function test_firstArrowSelectsFirstItem() {
            const list = findChild(browser, "fileList")
            list.forceActiveFocus()
            keyClick(Qt.Key_Down)
            compare(browser.selectedName, browser.visibleFiles[0].name)
            compare(list.currentIndex, 0)
        }
        function test_sortAndViewChangeKeepSelectionAndFocus() {
            const list = findChild(browser, "fileList")
            const grid = findChild(browser, "fileGrid")
            browser.selectIndex(2)
            const name = browser.selectedName
            browser.ascending = false
            compare(browser.selectedName, name)
            tryCompare(list, "currentIndex", 6)
            list.forceActiveFocus()
            browser.gridMode = true
            tryCompare(grid, "activeFocus", true)
            compare(grid.currentIndex, 6)
            keyClick(Qt.Key_Home)
            compare(browser.selectedName, browser.visibleFiles[0].name)
        }
        function test_filterRetainsOnlyVisibleSelection() {
            browser.selectIndex(0)
            const name = browser.selectedName
            browser.query = "png"
            compare(browser.selectedName, name)
            browser.query = "missing"
            compare(browser.selectedName, "")
            compare(findChild(browser, "fileList").currentIndex, -1)
        }
    }
}
