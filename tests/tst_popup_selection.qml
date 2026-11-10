import QtQuick
import QtTest
import QtMacOS

Rectangle {
    id: fixture
    width: 640; height: 480
    color: Theme.content
    MacPopupButton { id: choice; x: 80; y: 70; width: 260; model: ["Click Right Side", "Click Left Side", "Off"] }
    SignalSpy { id: activated; target: choice; signalName: "activated" }
    TestCase {
        name: "PopupSelection"
        when: windowShown
        function initTestCase() { failOnWarning(/.*/) }
        function init() {
            Theme.reducedMotion = true
            choice.popup.close()
            tryCompare(choice.popup, "visible", false)
            choice.currentIndex = 0
            activated.clear()
            mouseMove(fixture, 600, 450)
            Theme.reducedMotion = false
        }
        function cleanup() {
            Theme.reducedMotion = true
            choice.popup.close()
            tryCompare(choice.popup, "visible", false)
        }
        function list() { return choice.popup.contentItem }
        function marker() { return findChild(list().contentItem, "macPopupSelection") || findChild(list(), "macPopupSelection") }
        function open() { mouseClick(choice); tryCompare(choice.popup, "opened", true) }
        function test_hoverMovesThroughIntermediatePositions() {
            open()
            compare(marker().y, list().itemAtIndex(0).y)
            mouseMove(list().itemAtIndex(2), 25, 17)
            tryCompare(choice, "highlightedIndex", 2)
            const target = list().itemAtIndex(2).y
            verify(marker().y < target)
            tryVerify(() => marker().y > 0 && marker().y < target)
            compare(choice.currentIndex, 0)
            tryCompare(marker(), "y", target)
        }
        function test_keyboardReversalPreservesVelocityAndEscapeCancels() {
            open()
            keyClick(Qt.Key_Down)
            tryVerify(() => list().selectionVelocity > 10)
            const animation = findChild(list(), "macPopupSelectionAnimation")
            verify(animation)
            animation.paused = true
            const y = marker().y
            keyClick(Qt.Key_Up)
            verify(list().selectionVelocity > 0)
            compare(marker().y, y)
            animation.paused = false
            tryCompare(marker(), "y", list().itemAtIndex(0).y)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Escape)
            tryCompare(choice.popup, "visible", false)
            compare(choice.currentIndex, 0)
            compare(activated.count, 0)
        }
        function test_clickCommitsImmediatelyDuringMotion() {
            open()
            mouseMove(list().itemAtIndex(2), 25, 17)
            mouseClick(list().itemAtIndex(2), 25, 17)
            compare(choice.currentIndex, 2)
            compare(activated.count, 1)
            tryCompare(choice.popup, "visible", false)
            open()
            compare(marker().y, list().itemAtIndex(2).y)
            keyClick(Qt.Key_Up); keyClick(Qt.Key_Return)
            compare(choice.currentIndex, 1)
            compare(activated.count, 2)
        }
        function test_reducedMotionStopsCurrentMovement() {
            open()
            mouseMove(list().itemAtIndex(2), 25, 17)
            tryVerify(() => list().selectionVelocity > 10)
            Theme.reducedMotion = true
            compare(marker().y, list().itemAtIndex(2).y)
            compare(list().selectionVelocity, 0)
            keyClick(Qt.Key_Up)
            compare(marker().y, list().itemAtIndex(1).y)
        }
    }
}
