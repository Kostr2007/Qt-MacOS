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
            list.forceActiveFocus(); list.currentIndex = 0
            keyClick(Qt.Key_Down)
            compare(list.currentIndex, 1)
            compare(browser.selectedName, browser.visibleFiles[1].name)
        }
        function test_gridNavigation() {
            browser.gridMode = true
            const grid = findChild(browser, "fileGrid")
            grid.forceActiveFocus(); grid.currentIndex = 0
            keyClick(Qt.Key_Right)
            compare(grid.currentIndex, 1)
            compare(browser.selectedName, browser.visibleFiles[1].name)
        }
    }
}
