import QtQuick
import QtQuick.Window
import QtTest
import QtMacOS
import __DEMO__ as Demo

TestCase {
    name: "NavigationReplay"
    when: windowShown
    Component { id: scene; Demo.SettingsMain { presentation: true } }
    property var app
    property string stage: "rest"
    function child(name) { return findChild(app.contentItem, name) || findChild(app, name) }
    function navRow(key) {
        const index = app.sections.findIndex(entry => entry.key === key)
        child("settingsNavigation").positionViewAtIndex(index, ListView.Contain)
        tryVerify(() => child("settingsItem_" + key) !== null)
        return child("settingsItem_" + key)
    }
    function take() {
        const row = child("settingsItem_Game Center")
        const point = row ? row.mapToItem(app.contentItem, row.width - 20, row.height / 2)
                          : child("settingsNavigation").mapToItem(app.contentItem, 200, 100)
        const indicator = child("settingsHoverIndicator")
        const state = {tag: stage, category: app.pageTitle, historyIndex: app.historyIndex,
            helpVisible: child("mouseHelp").visible, helpOpacity: child("mouseHelp").opacity,
            helpScale: child("mouseHelp").scale, backScale: child("preferencesBack").scale,
            backDown: child("preferencesBack").down, advancedVisible: child("advancedDialog").visible,
            contentOpacity: child("preferencesPage") ? child("preferencesPage").opacity : 1,
            hoverY: indicator ? indicator.y : -1, hoverOpacity: indicator ? indicator.opacity : 0,
            hoverTarget: child("preferencesSidebar").hoverTargetY,
            hoverVelocity: child("preferencesSidebar").hoverVelocity,
            helpX: child("mouseHelp").x,
            helpCenterX: child("mouseHelp").contentItem.mapToItem(app.contentItem,
                child("mouseHelp").contentItem.width / 2, 0).x,
            probe_x: point.x, probe_y: point.y}
        verify(interactionRecorder.sample(state))
    }
    function frames(tag, count) {
        stage = tag
        for (let n = 0; n < count; ++n) { wait(16); take() }
    }
    function click(item) { mouseMove(item, item.width / 2, item.height / 2); mouseClick(item); }
    function test_replay() {
        failOnWarning(/.*/)
        app = createTemporaryObject(scene, null)
        verify(app)
        Theme.dark = __DARK__; Theme.reducedMotion = __REDUCED__
        verify(waitForRendering(app.contentItem))
        mouseMove(app.contentItem, 600, 700); wait(250)
        verify(interactionRecorder.start(__OUTPUT__, app, true))
        frames("rest", 2)
        for (const key of ["Game Center", "iCloud", "Wallet & Apple Pay", "Game Center"]) {
            mouseMove(navRow(key), 150, 22)
            frames("hover-" + key, 5)
        }
        for (const key of ["iCloud", "Game Center", "iCloud", "Game Center"]) {
            mouseMove(navRow(key), 150, 22)
            frames("hover-reversal-" + key, 2)
        }
        click(navRow("Game Center")); frames("select-game", 9)
        click(navRow("iCloud")); frames("select-cloud", 9)
        mouseMove(child("preferencesBack"), 18, 18)
        mousePress(child("preferencesBack")); frames("back-held", 4)
        mouseRelease(child("preferencesBack")); frames("back-arrival", 9)
        click(child("preferencesForward")); frames("forward-arrival", 9)
        // Re-enter Mouse without reconstructing its controls.
        app.navigate("Mouse"); frames("mouse-arrival", 9)
        mouseMove(child("helpButton"), 16, 16)
        mousePress(child("helpButton")); wait(90)
        mouseRelease(child("helpButton")); stage = "help-enter"; take()
        frames("help-enter", 10)
        keyClick(Qt.Key_Escape); frames("help-exit", 8)
        click(child("helpButton")); frames("help-reopen", 2)
        click(child("advancedButton")); frames("help-to-dialog", 9)
        keyClick(Qt.Key_Escape); frames("dialog-exit", 8)
        mouseMove(child("preferencesBack"), 18, 18); frames("tooltip-delay", 30)
        mouseMove(app.contentItem, 600, 700); frames("tooltip-exit", 8)
        verify(interactionRecorder.stop())
        app.close()
    }
}
