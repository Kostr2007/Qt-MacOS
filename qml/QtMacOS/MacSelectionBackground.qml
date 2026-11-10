pragma ComponentBehavior: Bound
import QtQuick
import QtMacOS

Rectangle {
    id: surface
    property bool hovered: false
    property bool selected: false
    property bool focused: false
    property color hoverColor: Theme.hover
    property color selectionColor: Theme.selection
    property bool animateSelection: false
    readonly property real selectionProgress: animateSelection ? selectionLayer.opacity : selected ? 1 : 0
    radius: Theme.radius
    color: selected && !animateSelection ? selectionColor : "transparent"
    // Interpolate opacity of a fixed RGB colour. Interpolating transparent black
    // to pale grey creates a dark intermediate colour even on a light sidebar.
    Rectangle {
        objectName: "hoverOverlay"
        anchors.fill: parent
        radius: surface.radius
        color: surface.hoverColor
        visible: !surface.selected
        opacity: surface.hovered && !surface.selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.colorDuration; easing.type: Theme.motionEasing } }
    }
    Rectangle {
        id: selectionLayer
        anchors.fill: parent
        radius: surface.radius
        color: surface.selectionColor
        Behavior on color { ColorAnimation { duration: Theme.colorDuration } }
        visible: surface.animateSelection
        opacity: surface.selected ? 1 : 0
        Behavior on opacity {
            enabled: surface.animateSelection
            NumberAnimation { duration: Theme.selectionDuration; easing.type: Easing.InOutCubic }
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: "transparent"
        border.width: surface.focused ? 2 : 0
        border.color: Theme.accent
    }
}
