import QtQuick
import QtQuick.Controls.Basic
import QtTest
import QtMacOS
import "../demo" as Demo

TestCase {
    name: "PreferencesIntegration"
    when: windowShown
    Component { id: preferencesComponent; Demo.SettingsMain {} }
    property var preferences
    function initTestCase() { failOnWarning(/.*/) }
    function init() {
        preferences = createTemporaryObject(preferencesComponent, null)
        verify(preferences !== null)
        verify(waitForRendering(preferences.contentItem))
    }
    function child(name) { return findChild(preferences, name) }
    function test_slidersAreIndependentAndKeyboardAccessible() {
        const slider = child("trackingSlider")
        slider.forceActiveFocus()
        keyClick(Qt.Key_Right)
        verify(preferences.trackingSpeed > 0.45)
        compare(preferences.doubleClickSpeed, 0.79)
        compare(preferences.scrollingSpeed, 0.56)
        for (let i = 0; i < 20; ++i) keyClick(Qt.Key_Left)
        compare(preferences.trackingSpeed, 0)
        for (let i = 0; i < 20; ++i) keyClick(Qt.Key_Right)
        compare(preferences.trackingSpeed, 1)
    }
    function test_sliderPointerAndBounds() {
        const slider = child("scrollingSlider")
        mouseClick(slider, slider.width * 0.2, 16)
        verify(preferences.scrollingSpeed < 0.4)
        verify(preferences.scrollingSpeed >= 0)
        compare(preferences.trackingSpeed, 0.45)
    }
    function test_switchMouseAndKeyboard() {
        const control = child("naturalSwitch")
        compare(preferences.naturalScrolling, false)
        mouseClick(control)
        compare(preferences.naturalScrolling, true)
        control.forceActiveFocus(); keyClick(Qt.Key_Space)
        compare(preferences.naturalScrolling, false)
    }
    function test_disabledControlsDoNotChangeSettings() {
        const slider = child("trackingSlider")
        const toggle = child("naturalSwitch")
        slider.enabled = false; toggle.enabled = false
        mouseClick(slider, slider.width * 0.8, 16)
        mouseClick(toggle)
        compare(preferences.trackingSpeed, 0.45)
        compare(preferences.naturalScrolling, false)
    }
    function test_appearanceChangePreservesValues() {
        preferences.trackingSpeed = 0.2
        child("trackingSlider").forceActiveFocus()
        const previous = Theme.dark
        keySequence("Ctrl+Shift+L")
        tryCompare(Theme, "dark", !previous)
        compare(child("trackingSlider").value, 0.2)
        compare(preferences.trackingSpeed, 0.2)
    }
    function test_enumPopupAndEscape() {
        const control = child("secondaryPopup")
        control.forceActiveFocus(); keyClick(Qt.Key_Down)
        compare(preferences.secondaryClick, 1)
        keyClick(Qt.Key_Space)
        tryCompare(control.popup, "visible", true)
        keyClick(Qt.Key_Escape)
        tryCompare(control.popup, "visible", false)
        compare(control.activeFocus, true)
    }
    function test_enumSelectionByPointer() {
        const control = child("secondaryPopup")
        mouseClick(control)
        tryCompare(control.popup, "visible", true)
        const options = control.popup.contentItem
        tryCompare(options, "count", 3)
        mouseClick(options.itemAtIndex(2))
        tryCompare(preferences, "secondaryClick", 2)
        tryCompare(control.popup, "visible", false)
    }
    function test_advancedResetUpdatesControls() {
        preferences.trackingSpeed = 0.12
        preferences.naturalScrolling = true
        preferences.secondaryClick = 2
        mouseClick(child("advancedButton"))
        const dialog = child("advancedDialog")
        tryCompare(dialog, "visible", true)
        mouseClick(dialog.standardButton(Dialog.Reset))
        compare(preferences.trackingSpeed, 0.45)
        compare(child("trackingSlider").value, 0.45)
        compare(preferences.naturalScrolling, false)
        compare(child("naturalSwitch").checked, false)
        compare(preferences.secondaryClick, 0)
        mouseClick(dialog.standardButton(Dialog.Ok))
        tryCompare(dialog, "visible", false)
        tryCompare(child("advancedButton"), "activeFocus", true)
    }
    function test_helpAndBluetoothAreRealOverlays() {
        mouseClick(child("helpButton"))
        tryCompare(child("mouseHelp"), "visible", true)
        keyClick(Qt.Key_Escape)
        tryCompare(child("mouseHelp"), "visible", false)
        mouseClick(child("bluetoothButton"))
        tryCompare(child("bluetoothDialog"), "visible", true)
        keyClick(Qt.Key_Escape)
        tryCompare(child("bluetoothDialog"), "visible", false)
    }
    function test_navigationKeepsValues() {
        preferences.trackingSpeed = 0.6
        preferences.navigate("Sound")
        compare(preferences.pageTitle, "Sound")
        mouseClick(child("preferencesBack"))
        compare(preferences.pageTitle, "Mouse")
        compare(child("trackingSlider").value, 0.6)
    }
    function test_sidebarSearch() {
        keySequence(StandardKey.Find)
        const field = child("settingsSearch")
        tryCompare(field, "activeFocus", true)
        keyClick("m"); keyClick("o"); keyClick("u")
        compare(child("settingsNavigation").count, 1)
    }
    function test_windowCloseUsesSharedShell() {
        mouseClick(child("windowClose"))
        tryCompare(preferences, "visible", false)
    }
}
