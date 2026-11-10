import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.ToolTip {
    id: tip
    objectName: "navigationToolTip"
    delay: 650
    timeout: 4000
    padding: 8
    font.pixelSize: 12
    palette.toolTipText: Theme.text
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.colorDuration; easing.type: Theme.motionEasing }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dismissDuration }
    }
    background: Rectangle {
        implicitWidth: 80
        implicitHeight: 30
        radius: 7
        color: Theme.settingsGroup
        border.color: Theme.border
        antialiasing: true
    }
}
