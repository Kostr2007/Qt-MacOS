import QtQuick
import QtTest
import QtMacOS
import "../demo" as Demo

TestCase {
    name: "HigDetails"
    when: windowShown
    property var app
    Component { id: scene; Demo.SettingsMain { presentation: true } }
    Component { id: mirroredSwitch; MacSwitch { width: 60; LayoutMirroring.enabled: true } }
    function initTestCase() { failOnWarning(/.*/) }
    function init() {
        app = createTemporaryObject(scene, null)
        verify(app)
        verify(waitForRendering(app.contentItem))
        mouseMove(app.contentItem, 600, 700)
        wait(200)
    }
    function child(name) { return findChild(app.contentItem, name) || findChild(app, name) }
    function sidebar() { return child("preferencesSidebar") }
    function focusedRow(key) {
        tryVerify(() => child("settingsItem_" + key) && child("settingsItem_" + key).activeFocus)
    }
    function test_searchClearRetainsCategoryAndFocus() {
        const search = child("settingsSearch")
        search.text = "sound"
        compare(sidebar().visibleEntries.length, 1)
        compare(app.pageTitle, "Mouse")
        mouseClick(child("settingsClearSearch"))
        compare(search.text, "")
        compare(search.activeFocus, true)
        compare(app.pageTitle, "Mouse")
        compare(child("settingsClearSearch").visible, false)
        search.text = "Mouse"
        sidebar().focusSearch()
        compare(search.selectedText, "Mouse")
    }
    function test_escapeClearsThenReturnsToSelectedRow() {
        const search = child("settingsSearch")
        sidebar().focusSearch(); search.text = "Sound"
        keyClick(Qt.Key_Escape)
        compare(search.text, "")
        compare(search.activeFocus, true)
        keyClick(Qt.Key_Escape)
        focusedRow("Mouse")
        compare(app.pageTitle, "Mouse")
    }
    function test_keyboardBrowsesResultsThenActivates() {
        sidebar().focusSearch()
        child("settingsSearch").text = "o"
        keyClick(Qt.Key_Down)
        const first = sidebar().visibleEntries[0].key
        focusedRow(first)
        compare(child("settingsItem_" + first).background.hovered, true)
        compare(app.pageTitle, "Mouse")
        keyClick(Qt.Key_Down)
        const second = sidebar().visibleEntries[1].key
        focusedRow(second)
        compare(app.pageTitle, "Mouse")
        keyClick(Qt.Key_Return)
        compare(app.pageTitle, second)
        keyClick(Qt.Key_Home); focusedRow(first)
        keyClick(Qt.Key_Space)
        compare(app.pageTitle, first)
        keyClick(Qt.Key_End)
        focusedRow(sidebar().visibleEntries[sidebar().visibleEntries.length - 1].key)
    }
    function test_noResultsDoesNotReplaceSelectionOrHistory() {
        const history = app.historyIndex
        sidebar().focusSearch()
        child("settingsSearch").text = "zzzz-no-matching-category"
        compare(sidebar().visibleEntries.length, 0)
        compare(child("settingsNoResults").visible, true)
        keyClick(Qt.Key_Down); keyClick(Qt.Key_Return)
        compare(app.pageTitle, "Mouse")
        compare(app.historyIndex, history)
        compare(child("settingsSearch").activeFocus, true)
        keyClick(Qt.Key_Escape)
        compare(child("settingsNoResults").visible, false)
    }
    function test_tabTreatsSidebarAsOneNavigationGroup() {
        sidebar().focusSearch()
        keyClick(Qt.Key_Tab)
        focusedRow("Mouse")
        keyClick(Qt.Key_Tab)
        compare(child("settingsItem_Mouse").activeFocus, false)
        for (const entry of sidebar().visibleEntries) {
            const item = child("settingsItem_" + entry.key)
            if (item) compare(item.activeFocus, false)
        }
    }
    function test_inactiveSelectionKeepsStableIdentity() {
        sidebar().focusResult(app.sections.findIndex(e => e.key === "Mouse"))
        focusedRow("Mouse")
        const selected = child("settingsItem_Mouse")
        sidebar().windowActive = false
        compare(selected.highlighted, true)
        compare(selected.background.selectionColor, Theme.inactiveSelection)
        compare(selected.background.focused, false)
        sidebar().windowActive = true
        compare(selected.background.selectionColor, "#0067d8")
        compare(app.pageTitle, "Mouse")
    }
    function test_switchPressKeepsCheckedOuterEdgeAnchored() {
        const s = child("naturalSwitch")
        const handle = findChild(s, "macSwitchHandle")
        s.checked = true
        tryCompare(handle, "x", s.indicator.width - handle.width - 3)
        mousePress(s)
        tryVerify(() => handle.width > 20)
        verify(Math.abs(handle.x + handle.width - (s.indicator.width - 3)) < 0.1)
        mouseRelease(s, -20, -20)
    }
    function test_switchSymbolsRapidInputAndMirroring() {
        const s = createTemporaryObject(mirroredSwitch, app.contentItem, {x: 600, y: 600})
        verify(s)
        compare(s.mirrored, true)
        s.showStateIndicators = true
        s.forceActiveFocus()
        for (let n = 0; n < 7; ++n) keyClick(Qt.Key_Space)
        compare(s.checked, true)
        const handle = findChild(s, "macSwitchHandle")
        tryCompare(handle, "x", 3)
        tryCompare(findChild(s, "macSwitchOnSymbol"), "opacity", 0.9)
        s.checked = false
        tryCompare(handle, "x", s.indicator.width - handle.width - 3)
        tryCompare(findChild(s, "macSwitchOffSymbol"), "opacity", 1)
    }
    function test_switchReduceMotionFinishesCurrentTravel() {
        const s = child("naturalSwitch")
        const handle = findChild(s, "macSwitchHandle")
        s.checked = true
        tryVerify(() => handle.x > 3 && handle.x < s.indicator.width - handle.width - 3)
        Theme.reducedMotion = true
        compare(handle.x, s.indicator.width - handle.width - 3)
        s.checked = false
        compare(handle.x, 3)
    }
}
