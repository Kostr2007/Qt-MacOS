import QtQuick
import QtTest
import QtMacOS
import __DEMO__ as Demo

TestCase {
    name: "PopupReplay"
    when: windowShown
    Component { id: scene; Demo.SettingsMain { presentation: true } }
    property var app
    property var choice
    property string stage: "rest"
    function list() { return choice.popup.contentItem }
    function marker() { return findChild(list().contentItem, "macPopupSelection") || findChild(list(), "macPopupSelection") }
    function take() {
        verify(interactionRecorder.sample({tag: stage, value: choice.currentIndex,
            highlighted: choice.highlightedIndex, popupVisible: choice.popup.visible,
            selectionY: marker().y, targetY: list().targetY, velocity: list().selectionVelocity,
            reduceMotion: Theme.reducedMotion}))
    }
    function frames(tag, count) { stage = tag; for (let i = 0; i < count; ++i) { wait(16); take() } }
    function hover(index) { mouseMove(list().itemAtIndex(index), 40, 17) }
    function open() { mouseMove(choice, 120, 16); mouseClick(choice); tryCompare(choice.popup, "opened", true) }
    function test_replay() {
        failOnWarning(/.*/)
        app = createTemporaryObject(scene, null)
        verify(app)
        Theme.dark = __DARK__; Theme.reducedMotion = __REDUCED__
        choice = findChild(app.contentItem, "secondaryPopup")
        verify(choice)
        verify(waitForRendering(app.contentItem))
        wait(200)
        verify(interactionRecorder.start(__OUTPUT__, app, true))
        open(); frames("menu-open", 3)
        hover(1); frames("hover-second", 3)
        hover(2); frames("hover-third", 8)
        hover(1); frames("reverse-second", 2)
        hover(0); frames("reverse-first", 8)
        keyClick(Qt.Key_Down); frames("keyboard-second", 3)
        keyClick(Qt.Key_Return); frames("commit-second", 8)
        compare(choice.currentIndex, 1)
        open(); frames("reopen-second", 3)
        hover(0); frames("cancel-preview", 3)
        keyClick(Qt.Key_Escape); frames("cancel", 8)
        compare(choice.currentIndex, 1)
        open(); hover(2); frames("fast-preview", 1)
        mouseClick(list().itemAtIndex(2), 40, 17); frames("fast-commit", 8)
        compare(choice.currentIndex, 2)
        verify(interactionRecorder.stop())
        app.close()
    }
}
