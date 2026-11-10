import QtQuick
import QtTest
import QtMacOS
import "../demo" as Demo

TestCase {
    name: "GalleryIntegration"
    when: windowShown
    Component { id: galleryComponent; Demo.Main {} }
    property var gallery
    function init() {
        gallery = createTemporaryObject(galleryComponent, null)
        verify(gallery !== null)
        verify(waitForRendering(gallery.contentItem))
    }
    function test_searchUpdatesBrowser() {
        const search = findChild(gallery, "search")
        mouseClick(findChild(gallery, "searchButton"))
        tryCompare(search, "activeFocus", true)
        keyClick("p"); keyClick("n"); keyClick("g")
        tryCompare(findChild(gallery, "browser"), "resultCount", 2)
    }
    function test_viewModeButtons() {
        const browser = findChild(gallery, "browser")
        mouseClick(findChild(gallery, "gridMode"))
        compare(browser.gridMode, true)
        mouseClick(findChild(gallery, "listMode"))
        compare(browser.gridMode, false)
    }
    function test_findShortcut() {
        const search = findChild(gallery, "search")
        findChild(gallery, "gridMode").forceActiveFocus()
        keySequence(StandardKey.Find)
        tryCompare(search, "activeFocus", true)
    }
    function test_navigationHistory() {
        gallery.navigate("Downloads")
        compare(findChild(gallery, "browser").resultCount, 3)
        mouseClick(findChild(gallery, "backButton"))
        compare(gallery.section, "Documents")
        compare(findChild(gallery, "finderSidebar").selectedTitle, "Documents")
        mouseClick(findChild(gallery, "forwardButton"))
        compare(gallery.section, "Downloads")
    }
    function test_windowButtons() {
        const sidebar = findChild(gallery, "finderSidebar")
        verify(findChild(sidebar, "windowClose") !== null)
        verify(findChild(sidebar, "windowMinimize") !== null)
        verify(findChild(sidebar, "windowZoom") !== null)
        mouseClick(findChild(sidebar, "windowClose"))
        tryCompare(gallery, "visible", false)
    }
    function test_themeButton() {
        const previous = Theme.dark
        mouseClick(findChild(gallery, "moreButton"))
        tryCompare(findChild(gallery, "viewMenu"), "opened", true)
        const item = findChild(gallery, "themeToggle")
        tryCompare(item, "visible", true)
        verify(item.width >= 200)
        mouseClick(item)
        tryCompare(Theme, "dark", !previous)
    }
    function test_reduceMotionMenu() {
        mouseClick(findChild(gallery, "moreButton"))
        tryCompare(findChild(gallery, "viewMenu"), "opened", true)
        mouseClick(findChild(gallery, "reduceMotionToggle"))
        tryCompare(Theme, "reducedMotion", true)
        Theme.reducedMotion = false
    }
}
