import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Menu {
    id: menu
    padding: 6
    transformOrigin: Item.TopRight
    palette.window: Theme.settingsGroup
    palette.text: Theme.text
    palette.highlight: Theme.activeSelection
    palette.highlightedText: "white"
    enter: MacPopupTransition {}
    exit: MacPopupTransition { appearing: false }
    background: Rectangle {
        implicitWidth: 220
        implicitHeight: 40
        radius: 9
        color: Theme.settingsGroup
        border.color: Theme.border
    }
}
