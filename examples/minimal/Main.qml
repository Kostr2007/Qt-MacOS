import QtQuick
import QtQuick.Controls.Basic
import QtMacOS

ApplicationWindow {
    id: window
    width: 480
    height: 330
    visible: true
    title: qsTr("Qt-MacOS consumer example")
    color: Theme.window

    Column {
        anchors.centerIn: parent
        width: Math.min(360, window.width - 40)
        spacing: 16
        MacBox {
            width: parent.width
            title: qsTr("Your application")
            MacLabel {
                width: parent.width
                text: qsTr("This screen uses the public QtMacOS module.")
                wrapMode: Text.WordWrap
            }
            MacTextField {
                id: nameField
                width: parent.width
                placeholderText: qsTr("Project name")
                Accessible.name: qsTr("Project name")
            }
            MacCheckBox {
                text: qsTr("Dark appearance")
                checked: Theme.dark
                onToggled: Theme.dark = checked
            }
            MacButton {
                text: qsTr("Create project")
                highlighted: true
                onClicked: result.text = qsTr("Created: %1").arg(nameField.text || qsTr("Untitled"))
            }
        }
        MacLabel {
            id: result
            width: parent.width
            role: MacLabel.Secondary
            text: qsTr("Your application owns the data and actions.")
        }
    }
}
