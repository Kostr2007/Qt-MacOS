pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Switch {
    id: control
    implicitWidth: text.length ? 52 + contentItem.implicitWidth + spacing : 52
    implicitHeight: 32
    padding: 4
    spacing: 8
    hoverEnabled: true
    property bool showStateIndicators: Theme.differentiateWithoutColor
    QtObject {
        id: motion
        property real position: control.visualPosition
        Behavior on position {
            enabled: !Theme.reducedMotion && !(control.down && control.position > 0 && control.position < 1)
            NumberAnimation { duration: Theme.releaseDuration; easing.type: Theme.motionEasing }
        }
    }
    Connections {
        target: Theme
        function onReducedMotionChanged() {
            if (Theme.reducedMotion)
                motion.position = Qt.binding(function() { return control.visualPosition; });
        }
    }
    indicator: Rectangle {
        implicitWidth: 44
        implicitHeight: 24
        x: control.text.length ? control.mirrored ? control.width - width - control.rightPadding : control.leftPadding : (control.width - width) / 2
        y: (control.height - height) / 2
        radius: 12
        color: control.checked ? Theme.settingsAccent : Theme.dark ? "#65656b" : "#dedee0"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
        opacity: control.enabled ? 1 : 0.45
        Behavior on color { ColorAnimation { duration: Theme.colorDuration } }
        Rectangle {
            objectName: "macSwitchOnSymbol"
            visible: control.showStateIndicators
            x: control.mirrored ? parent.width - 12 : 10
            anchors.verticalCenter: parent.verticalCenter
            width: 1.5; height: 7; radius: 0.75
            color: "white"
            opacity: control.checked ? 0.9 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.colorDuration } }
        }
        Rectangle {
            objectName: "macSwitchOffSymbol"
            visible: control.showStateIndicators
            x: control.mirrored ? 9 : parent.width - 15
            anchors.verticalCenter: parent.verticalCenter
            width: 6; height: 6; radius: 3
            color: "transparent"
            border.width: 1.2
            border.color: Theme.dark ? "#e4e4e7" : "#77777c"
            opacity: control.checked ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.colorDuration } }
        }
        Rectangle {
            objectName: "macSwitchHandle"
            x: 3 + (Theme.reducedMotion ? control.visualPosition : motion.position) * (parent.width - width - 6)
            y: 3
            width: control.down && !Theme.reducedMotion ? 21 : 18
            height: 18
            radius: 9
            color: "#ffffff"
            border.width: 0.5
            border.color: "#eeeeef"
            Behavior on width { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.pressDuration; easing.type: Theme.motionEasing } }
            Rectangle {
                z: -1
                x: -1
                y: 0
                width: parent.width + 2
                height: 20
                radius: 10
                color: "#16000000"
            }
        }
    }
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.enabled ? Theme.settingsText : Theme.settingsSecondary
        verticalAlignment: Text.AlignVCenter
        leftPadding: !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.mirrored ? control.indicator.width + control.spacing : 0
    }
}
