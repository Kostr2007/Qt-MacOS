import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.ToolButton {
    id: control
    property string symbol: "more"
    property color glyphColor: "#b6b6b8"
    // 0: independent button, -1/+1: left/right half of a shared capsule.
    property int capsuleSide: 0
    implicitWidth: 36
    implicitHeight: 36
    padding: 4
    hoverEnabled: true
    scale: down && enabled && !Theme.reducedMotion ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: control.down ? Theme.pressDuration : Theme.releaseDuration; easing.type: Theme.motionEasing } }
    Accessible.name: text
    MacToolTip {
        parent: control
        visible: control.hovered && !control.down && control.enabled && control.text.length > 0
        text: control.text
    }
    contentItem: FinderIcon {
        name: control.symbol
        color: control.glyphColor
        opacity: control.enabled ? 1 : 0.28
    }
    background: Rectangle {
        radius: control.capsuleSide ? Math.min(height / 2, 20) : 5
        color: "transparent"
        Rectangle {
            objectName: "toolButtonFeedback"
            anchors.fill: parent
            radius: parent.radius
            antialiasing: true
            // Composite the rounded shape and square inner half before applying
            // opacity; otherwise their overlap becomes a darker rectangle.
            layer.enabled: control.capsuleSide !== 0
            layer.smooth: true
            color: Theme.dark ? "white" : "black"
            opacity: !control.enabled ? 0 : control.down ? 0.15 : control.checked ? 0.10 : control.hovered ? 0.05 : 0
            Behavior on opacity { NumberAnimation { duration: control.down ? Theme.pressDuration : Theme.colorDuration } }
            Rectangle {
                visible: control.capsuleSide !== 0
                x: control.capsuleSide < 0 ? parent.width / 2 : 0
                width: parent.width / 2
                height: parent.height
                color: parent.color
            }
        }
        border.width: control.visualFocus ? 1 : 0
        border.color: control.glyphColor
    }
}
