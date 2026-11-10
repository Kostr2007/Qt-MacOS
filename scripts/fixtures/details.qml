import QtQuick
import QtQuick.Window
import QtTest
import QtMacOS
import __DEMO__ as Demo

TestCase {
    name: "DetailsReplay"
    when: windowShown
    Component { id: scene; Demo.SettingsMain {} }
    Component {
        id: otherScene
        Window {
            width: 240; height: 100
            flags: Qt.Dialog
            title: "Qt-MacOS focus check"
            color: "#eeeeef"
            Text { anchors.centerIn: parent; text: "Window activation check" }
        }
    }
    property var app
    property string stage: "rest"
    function child(name) { return findChild(app.contentItem, name) || findChild(app, name) }
    function take() {
        const s = child("naturalSwitch")
        const h = findChild(s, "macSwitchHandle")
        const selected = child("settingsItem_" + app.pageTitle)
        verify(interactionRecorder.sample({tag: stage, category: app.pageTitle,
            windowActive: app.active, sidebarActive: child("preferencesSidebar").windowActive,
            focus: app.activeFocusItem ? app.activeFocusItem.objectName : "",
            search: child("settingsSearch").text, resultCount: child("settingsNavigation").count,
            clearVisible: child("settingsClearSearch").visible, noResults: child("settingsNoResults").visible,
            selectedColor: selected ? selected.background.selectionColor.toString() : "",
            checked: s.checked, switchX: h.x, switchWidth: h.width,
            symbols: s.showStateIndicators, reduceMotion: Theme.reducedMotion}))
    }
    function frames(tag, count) { stage = tag; for (let i = 0; i < count; ++i) { wait(16); take() } }
    function test_replay() {
        failOnWarning(/.*/)
        app = createTemporaryObject(scene, null)
        verify(app)
        Theme.dark = __DARK__; Theme.reducedMotion = __REDUCED__
        Theme.differentiateWithoutColor = true
        app.requestActivate()
        tryCompare(app, "active", true)
        verify(waitForRendering(app.contentItem))
        mouseMove(app.contentItem, 600, 700); wait(220)
        verify(interactionRecorder.start(__OUTPUT__, app, true))
        frames("rest", 3)
        keyClick(Qt.Key_F, Qt.ControlModifier)
        tryCompare(child("settingsSearch"), "activeFocus", true)
        for (const key of [Qt.Key_S, Qt.Key_O, Qt.Key_U, Qt.Key_N, Qt.Key_D]) keyClick(key)
        frames("search-results", 4)
        keyClick(Qt.Key_Down); frames("result-focus", 3)
        keyClick(Qt.Key_Return); frames("result-open", 7)
        child("preferencesSidebar").focusSearch()
        keyClick(Qt.Key_Z); frames("no-results", 4)
        keyClick(Qt.Key_Escape); frames("search-cleared", 3)
        keyClick(Qt.Key_Escape); frames("selection-focus", 3)
        app.navigate("Mouse"); wait(220)
        const s = child("naturalSwitch")
        mouseMove(s, s.width / 2, s.height / 2)
        mousePress(s); frames("switch-press", 3)
        mouseRelease(s); frames("switch-on", 9)
        mousePress(s); frames("switch-on-press", 3)
        mouseRelease(s); frames("switch-off", 9)
        for (let i = 0; i < 5; ++i) {
            mouseClick(s); frames("switch-reversal", 1)
        }
        frames("switch-settled", 8)
        mouseMove(app.contentItem, 600, 700)
        const other = createTemporaryObject(otherScene, null)
        verify(other)
        other.show(); other.requestActivate()
        tryCompare(app, "active", false)
        frames("inactive-window", 9)
        other.close(); app.requestActivate()
        tryCompare(app, "active", true)
        frames("active-window", 9)
        verify(interactionRecorder.stop())
        app.close()
    }
}
