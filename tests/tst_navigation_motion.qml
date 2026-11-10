import QtQuick
import QtTest
import QtMacOS
import "../demo" as Demo

TestCase {
    name: "NavigationMotion"
    when: windowShown
    Component { id: settings; Demo.SettingsMain {} }
    property var app
    function initTestCase() { failOnWarning(/.*/) }
    function init() {
        app = createTemporaryObject(settings, null)
        verify(app)
        verify(waitForRendering(app.contentItem))
        mouseMove(app.contentItem, 600, 700)
        wait(220)
    }
    function child(name) { return findChild(app.contentItem, name) || findChild(app, name) }
    function row(key) {
        const index = app.sections.findIndex(e => e.key === key)
        child("settingsNavigation").positionViewAtIndex(index, ListView.Contain)
        tryVerify(() => child("settingsItem_" + key) !== null)
        return child("settingsItem_" + key)
    }
    function test_helpAnimatesAndStaysAttachedInsideWindow() {
        const help = child("mouseHelp")
        const button = child("helpButton")
        mouseClick(button)
        tryCompare(help, "visible", true)
        tryVerify(() => help.opacity > 0 && help.opacity < 1)
        tryCompare(help, "opened", true)
        verify(help.viewportX >= help.edgeMargin)
        verify(help.viewportX + help.width <= app.width - help.edgeMargin + 1)
        verify(help.viewportY >= help.edgeMargin)
        if (help.above) verify(help.viewportY + help.height <= help.anchorPosition.y + 1)
        else verify(help.viewportY >= help.anchorPosition.y + button.height)
        keyClick(Qt.Key_Escape)
        tryCompare(help, "visible", false)
        tryCompare(button, "activeFocus", true)
    }
    function test_helpToggleCanReverseAnExit() {
        const help = child("mouseHelp")
        const button = child("helpButton")
        mouseClick(button)
        tryCompare(help, "opened", true)
        mouseClick(button)
        compare(help.requestedVisible, false)
        mouseClick(button)
        tryCompare(help, "requestedVisible", true)
        tryCompare(help, "opened", true)
        compare(help.opacity, 1)
    }
    function test_helpCenterIsStableDuringAnchorReleaseAndReveal() {
        const button = child("helpButton")
        const help = child("mouseHelp")
        mousePress(button)
        wait(90)
        verify(button.scale < 1)
        mouseRelease(button)
        compare(help.placementAnchor.parent, app.contentItem)
        const center = help.viewportX + help.width / 2
        for (let i = 0; i < 14; ++i) {
            const visual = help.contentItem.mapToItem(app.contentItem,
                help.contentItem.width / 2, help.contentItem.height / 2)
            verify(Math.abs(visual.x - center) < 0.75, "Popover center moved during reveal: " + visual.x + " vs " + center)
            wait(16)
        }
        mouseClick(app.contentItem, 600, 650)
        tryCompare(help, "visible", false)
    }
    function test_helpRepositionsOnResizeAndDismissesOnNavigation() {
        const help = child("mouseHelp")
        mouseClick(child("helpButton"))
        tryCompare(help, "opened", true)
        app.width = 1100
        app.height = 740
        tryVerify(() => Math.abs(help.anchorPosition.x - child("helpButton").mapToItem(app.contentItem, 0, 0).x) < 1)
        tryVerify(() => help.viewportX + help.width <= app.width - help.edgeMargin + 1)
        tryVerify(() => help.viewportY + help.height <= app.height - help.edgeMargin + 1)
        app.navigate("Sound")
        tryCompare(help, "visible", false)
        compare(app.pageTitle, "Sound")
    }
    function test_helpOutsideClickOpensDialogWithoutExtraClick() {
        const help = child("mouseHelp")
        mouseClick(child("helpButton"))
        tryCompare(help, "opened", true)
        mouseClick(child("advancedButton"))
        tryCompare(child("advancedDialog"), "opened", true)
        tryCompare(help, "visible", false)
        keyClick(Qt.Key_Escape)
        tryCompare(child("advancedDialog"), "visible", false)
    }
    function test_sidebarHoverAppearsAndMovesWithoutTeleporting() {
        const game = row("Game Center")
        const cloud = row("iCloud")
        const marker = child("settingsHoverIndicator")
        mouseMove(game, 150, 22)
        verify(marker.opacity < 0.15)
        tryCompare(marker, "opacity", 1)
        const first = marker.y
        const target = cloud.parent.y + cloud.y
        mouseMove(cloud, 150, 22)
        verify(Math.abs(marker.y - target) > 1)
        tryVerify(() => marker.y > Math.min(first, target) && marker.y < Math.max(first, target))
        tryCompare(marker, "y", target)
        mouseMove(game, 150, 22)
        tryCompare(marker, "y", first)
        mouseMove(app.contentItem, 600, 700)
        tryCompare(marker, "opacity", 0)
    }
    function test_sidebarSelectionFadesAndLatestCategoryWins() {
        const game = row("Game Center")
        mouseClick(game)
        compare(app.pageTitle, "Game Center")
        tryVerify(() => game.background.selectionProgress > 0 && game.background.selectionProgress < 1)
        mouseClick(row("iCloud"))
        mouseClick(row("Game Center"))
        compare(app.pageTitle, "Game Center")
        tryCompare(game.background, "selectionProgress", 1)
        tryCompare(row("iCloud").background, "selectionProgress", 0)
        tryCompare(child("settingsHoverIndicator"), "opacity", 0)
    }
    function test_hoverReversalPreservesMomentumAndReducedMotionStopsIt() {
        const game = row("Game Center")
        const cloud = row("iCloud")
        const sidebar = child("preferencesSidebar")
        const marker = child("settingsHoverIndicator")
        mouseMove(game, 150, 22)
        tryCompare(marker, "opacity", 1)
        mouseMove(cloud, 150, 22)
        tryVerify(() => sidebar.hoverVelocity > 20)
        const previousY = marker.y
        mouseMove(game, 150, 22)
        verify(sidebar.hoverVelocity > 0, "Retargeting must preserve velocity")
        verify(Math.abs(marker.y - previousY) < 3, "Retargeting must not jump")
        tryCompare(marker, "y", sidebar.hoverTargetY)
        mouseMove(cloud, 150, 22)
        tryVerify(() => sidebar.hoverVelocity > 20)
        Theme.reducedMotion = true
        compare(marker.y, sidebar.hoverTargetY)
        compare(sidebar.hoverVelocity, 0)
    }
    function test_filterRemovesHoverWithoutLeavingAnOrphanPill() {
        mouseMove(row("Game Center"), 150, 22)
        const marker = child("settingsHoverIndicator")
        tryCompare(marker, "opacity", 1)
        child("preferencesSidebar").searchText = "Mouse"
        tryCompare(child("settingsNavigation"), "count", 1)
        tryCompare(marker, "opacity", 0)
    }
    function test_backForwardPressAndPageArrivalPreserveValues() {
        app.trackingSpeed = 0.63
        app.navigate("Sound")
        tryCompare(app, "pageProgress", 1)
        const back = child("preferencesBack")
        mousePress(back)
        compare(app.pageTitle, "Sound")
        tryVerify(() => back.scale < 0.99)
        const feedback = findChild(back, "toolButtonFeedback")
        tryVerify(() => feedback.opacity > 0.08)
        mouseRelease(back)
        compare(app.pageTitle, "Mouse")
        verify(child("preferencesPage").opacity < 1)
        tryCompare(app, "pageProgress", 1)
        tryCompare(back, "scale", 1)
        compare(child("trackingSlider").value, 0.63)
        mouseClick(child("preferencesForward"))
        compare(app.pageTitle, "Sound")
        tryCompare(app, "pageProgress", 1)
    }
    function test_historyInterruptionsDoNotQueueOldPages() {
        app.navigate("Sound"); app.navigate("Focus"); app.navigate("Keyboard")
        const back = child("preferencesBack")
        mouseClick(back); mouseClick(back)
        compare(app.pageTitle, "Sound")
        mouseClick(child("preferencesForward"))
        compare(app.pageTitle, "Focus")
        tryCompare(app, "pageProgress", 1)
        compare(app.pageTitle, "Focus")
        compare(child("preferencesSidebar").currentKey, "Focus")
    }
    function test_tooltipWaitsThenFadesAndDismisses() {
        const button = child("preferencesBack")
        const tip = findChild(button, "navigationToolTip")
        mouseMove(button, 18, 18)
        compare(tip.visible, false)
        tryCompare(tip, "visible", true, 1500)
        tryCompare(tip, "opened", true)
        mouseMove(app.contentItem, 600, 700)
        tryCompare(tip, "visible", false)
    }
    function test_reducedMotionKeepsNavigationImmediate() {
        Theme.reducedMotion = true
        const game = row("Game Center")
        mouseMove(game, 150, 22)
        compare(child("settingsHoverIndicator").opacity, 1)
        mouseClick(game)
        compare(game.background.selectionProgress, 1)
        compare(app.pageProgress, 1)
        app.navigate("Mouse")
        compare(app.pageProgress, 1)
        mouseClick(child("helpButton"))
        tryCompare(child("mouseHelp"), "opened", true)
        compare(child("mouseHelp").scale, 1)
        compare(child("mouseHelp").opacity, 1)
    }
}
