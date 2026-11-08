import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ToolButton {
    id: control
    property string symbol: "more"
    property color glyphColor: "#b6b6b8"
    implicitWidth: 36
    implicitHeight: 36
    padding: 4
    hoverEnabled: true
    Accessible.name: text
    Basic.ToolTip.visible: hovered && text.length > 0
    Basic.ToolTip.text: text
    Basic.ToolTip.delay: 650
    contentItem: FinderIcon {
        name: control.symbol
        color: control.glyphColor
        opacity: control.enabled ? 1 : 0.28
    }
    background: Rectangle {
        radius: 5
        color: control.down ? "#30ffffff" : control.checked ? "#22ffffff" : control.hovered ? "#12ffffff" : "transparent"
        border.width: control.visualFocus ? 1 : 0
        border.color: control.glyphColor
    }
}
