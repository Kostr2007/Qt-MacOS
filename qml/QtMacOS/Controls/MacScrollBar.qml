import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.ScrollBar {
    id: control
    property int hideDelay: 750
    readonly property bool interacting: active || hovered || pressed
    property bool recentlyActive: false
    padding: 2
    hoverEnabled: true
    minimumSize: 0.08
    implicitWidth: vertical ? 14 : 48
    implicitHeight: vertical ? 48 : 14
    onInteractingChanged: {
        if (interacting) {
            hideTimer.stop();
            recentlyActive = true;
        } else {
            hideTimer.restart();
        }
    }
    Timer {
        id: hideTimer
        interval: control.hideDelay
        onTriggered: control.recentlyActive = false
    }
    background: Item {}
    // Keep a generous hit area without reserving a visible gutter in the view.
    contentItem: Item {
        implicitWidth: 10
        implicitHeight: 10
        opacity: control.policy === Basic.ScrollBar.AlwaysOn
                 || (control.size < 1 && (control.interacting || control.recentlyActive))
                 ? (control.enabled ? 1 : 0.35) : 0
        Behavior on opacity {
            NumberAnimation { duration: Theme.reducedMotion ? 0 : control.interacting ? 100 : 220 }
        }
        Rectangle {
            objectName: "macScrollThumb"
            anchors.centerIn: parent
            width: control.vertical ? (control.hovered || control.pressed ? 7 : 4) : parent.width
            height: control.horizontal ? (control.hovered || control.pressed ? 7 : 4) : parent.height
            radius: Math.min(width, height) / 2
            antialiasing: true
            color: Theme.dark ? "#b0b0b6" : "#65656b"
            opacity: control.pressed ? 0.8 : control.hovered ? 0.65 : 0.46
            Behavior on width { enabled: control.vertical; NumberAnimation { duration: Theme.colorDuration; easing.type: Theme.motionEasing } }
            Behavior on height { enabled: control.horizontal; NumberAnimation { duration: Theme.colorDuration; easing.type: Theme.motionEasing } }
            Behavior on opacity { NumberAnimation { duration: Theme.colorDuration } }
        }
    }
}
