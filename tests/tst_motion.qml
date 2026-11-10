import QtQuick
import QtQuick.Controls.Basic as Basic
import QtTest
import QtMacOS

Rectangle {
    id: fixture
    width: 640; height: 480
    color: Theme.content
    MacPushButton { id: button; x: 35; y: 40; text: "Apply changes"; highlighted: true }
    MacSwitch { id: toggle; x: 35; y: 115 }
    MacSlider { id: slider; x: 35; y: 190; width: 350; from: 0; to: 1; stepSize: 0.1 }
    MacPopupButton { id: choice; x: 35; y: 285; model: ["Studio", "Library", "Archive"] }
    MacTextField { id: field; x: 35; y: 365; text: "Keyboard focus" }
    MacDialog {
        id: dialog
        parent: fixture
        x: 210; y: 70; width: 340
        title: "Changes applied"
        standardButtons: Basic.Dialog.Ok
        contentItem: MacLabel { text: "Your selection stays in place." }
    }
    SignalSpy { id: clicked; target: button; signalName: "clicked" }
    TestCase {
        name: "InteractionMotion"
        when: windowShown
        function initTestCase() { failOnWarning(/.*/) }
        function init() {
            Theme.reducedMotion = true
            dialog.close(); choice.popup.close()
            tryCompare(dialog, "visible", false)
            tryCompare(choice.popup, "visible", false)
            button.enabled = true; toggle.checked = false; slider.value = 0.2
            clicked.clear()
            mouseMove(fixture, 600, 450)
            Theme.reducedMotion = false
        }
        function cleanup() {
            mouseRelease(fixture, 600, 450)
            Theme.reducedMotion = true
            dialog.close(); choice.popup.close()
            tryCompare(dialog, "visible", false)
            tryCompare(choice.popup, "visible", false)
            Theme.reducedMotion = false
        }
        function test_pressReleaseAndCancel() {
            mousePress(button)
            compare(button.down, true)
            compare(clicked.count, 0)
            tryVerify(() => button.scale < 0.999)
            mouseRelease(button)
            compare(clicked.count, 1)
            tryCompare(button, "scale", 1)
            mousePress(button)
            mouseMove(fixture, 600, 450)
            mouseRelease(fixture, 600, 450)
            compare(clicked.count, 1)
            tryCompare(button, "scale", 1)
        }
        function test_highlightedButtonHasPressedFeedback() {
            wait(Theme.colorDuration + 30)
            const resting = button.background.color.toString()
            button.forceActiveFocus()
            keyPress(Qt.Key_Space)
            tryVerify(() => button.background.color.toString() !== resting)
            compare(clicked.count, 0)
            keyRelease(Qt.Key_Space)
            compare(clicked.count, 1)
            tryCompare(button, "scale", 1)
        }
        function test_rapidSwitchInputIsNotBlockedByMotion() {
            toggle.forceActiveFocus()
            for (let i = 0; i < 7; ++i) keyClick(Qt.Key_Space)
            compare(toggle.checked, true)
            const handle = findChild(toggle, "macSwitchHandle")
            tryCompare(handle, "x", toggle.indicator.width - handle.width - 3)
            compare(toggle.activeFocus, true)
        }
        function test_sliderDragTracksPointerAndKeyboardSettles() {
            mousePress(slider, slider.width * 0.2, 16)
            mouseMove(slider, slider.width * 0.8, 16)
            verify(slider.pressed)
            verify(slider.value >= 0.7)
            const handle = findChild(slider, "macSliderHandle")
            verify(Math.abs(handle.x - slider.visualPosition * (slider.width - handle.width)) < 1)
            mouseRelease(slider, slider.width * 0.8, 16)
            slider.forceActiveFocus()
            keyClick(Qt.Key_Left)
            const expected = slider.visualPosition * (slider.width - handle.width)
            tryVerify(() => Math.abs(handle.x - expected) < 0.1)
            tryCompare(handle, "scale", 1)
        }
        function test_dialogEscapeDuringEntryReturnsFocus() {
            field.forceActiveFocus()
            dialog.open()
            tryCompare(dialog, "visible", true)
            keyClick(Qt.Key_Escape)
            tryCompare(dialog, "visible", false)
            tryCompare(field, "activeFocus", true)
            dialog.open()
            tryCompare(dialog, "opened", true)
            compare(dialog.opacity, 1)
            compare(dialog.scale, 1)
            dialog.close()
            tryCompare(dialog, "visible", false)
        }
        function test_popupCanDismissAndReopen() {
            choice.forceActiveFocus()
            keyClick(Qt.Key_Space)
            tryCompare(choice.popup, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(choice.popup, "visible", false)
            compare(choice.activeFocus, true)
            keyClick(Qt.Key_Space)
            tryCompare(choice.popup, "opened", true)
            compare(choice.popup.opacity, 1)
            compare(choice.popup.scale, 1)
        }
        function test_reducedMotionKeepsActionsImmediate() {
            Theme.reducedMotion = true
            mousePress(button)
            compare(button.down, true)
            compare(button.scale, 1)
            mouseRelease(button)
            compare(clicked.count, 1)
            mouseClick(toggle)
            const handle = findChild(toggle, "macSwitchHandle")
            compare(toggle.checked, true)
            compare(handle.x, toggle.indicator.width - handle.width - 3)
            dialog.open()
            tryCompare(dialog, "opened", true)
            compare(dialog.scale, 1)
            compare(dialog.opacity, 1)
        }
    }
}
