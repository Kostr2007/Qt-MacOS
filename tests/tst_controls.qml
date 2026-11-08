import QtQuick
import QtQuick.Controls.Basic
import QtTest
import QtMacOS

Item {
    width: 640; height: 480
    MacButton { id: button; x: 10; y: 10; text: "Generate" }
    MacCheckBox { id: check; x: 10; y: 60; text: "Enabled" }
    MacTextField { id: field; x: 10; y: 110; width: 220 }
    MacComboBox { id: combo; x: 10; y: 160; model: ["One", "Two", "Three"] }
    SearchField { id: search; x: 10; y: 210; width: 220 }
    Sidebar { id: sidebar; x: 300; width: 220; height: 400; entries: [{title: "One"}, {title: "Two"}] }
    SignalSpy { id: clickSpy; target: button; signalName: "clicked" }
    SignalSpy { id: sidebarSpy; target: sidebar; signalName: "activated" }
    TestCase {
        name: "MacControls"
        when: windowShown
        function typeText(text) {
            for (let i = 0; i < text.length; ++i) keyClick(text[i])
        }
        function init() {
            button.enabled = true; clickSpy.clear(); check.checked = false
            field.text = ""; search.text = ""; Theme.dark = true
        }
        function test_buttonMouseAndKeyboard() {
            mouseClick(button); compare(clickSpy.count, 1)
            button.forceActiveFocus(); keyClick(Qt.Key_Space); compare(clickSpy.count, 2)
            button.enabled = false; mouseClick(button); compare(clickSpy.count, 2)
        }
        function test_checkKeyboard() {
            check.forceActiveFocus(); keyClick(Qt.Key_Space); compare(check.checked, true)
            keyClick(Qt.Key_Space); compare(check.checked, false)
        }
        function test_textEditing() {
            field.forceActiveFocus(); typeText("Obsidian")
            compare(field.text, "Obsidian")
            keyClick(Qt.Key_Backspace); compare(field.text, "Obsidia")
        }
        function test_comboKeyboard() {
            combo.currentIndex = 0; combo.forceActiveFocus()
            keyClick(Qt.Key_Down); compare(combo.currentIndex, 1)
        }
        function test_themePropagation() {
            const original = Theme.content.toString()
            Theme.dark = false
            tryVerify(() => Theme.content.toString() !== original)
            compare(field.color, Theme.text)
        }
        function test_searchInput() {
            search.forceActiveFocus(); typeText("level"); compare(search.text, "level")
        }
        function test_sidebarSelection() {
            sidebarSpy.clear()
            mouseClick(sidebar, 70, 110)
            compare(sidebar.currentIndex, 1); compare(sidebarSpy.count, 1)
        }
    }
}
