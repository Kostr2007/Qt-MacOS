pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Shapes
import QtQuick.Controls.Basic as Basic
import QtMacOS

Row {
    id: lights
    property real buttonDiameter: 15
    property bool dark: true
    property bool windowActive: true
    signal closeRequested
    signal minimizeRequested
    signal zoomRequested

    spacing: 10
    property bool showSymbols: closeButton.hovered || minimizeButton.hovered || zoomButton.hovered

    Basic.ToolButton {
        id: closeButton
        scale: down && !Theme.reducedMotion ? 0.90 : 1
        Behavior on scale { NumberAnimation { duration: closeButton.down ? Theme.pressDuration : Theme.releaseDuration; easing.type: Theme.motionEasing } }
        objectName: "windowClose"
        width: lights.buttonDiameter
        height: lights.buttonDiameter
        padding: 0
        hoverEnabled: true
        Accessible.name: qsTr("Close window")
        onClicked: lights.closeRequested()
        background: Rectangle {
            radius: width / 2
            antialiasing: true
            color: closeButton.down ? "#d94b44" : lights.windowActive || lights.showSymbols ? "#ff5f57" : lights.dark ? "#777779" : "#c5c5c7"
            border.width: 0.5
            border.color: lights.windowActive ? "#e84a43" : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.colorDuration } }
        }
        contentItem: Item {
            visible: lights.showSymbols || closeButton.visualFocus
            Shape {
                id: closeShape
                Component.onCompleted: {
                    if ("preferredRendererType" in closeShape && typeof Shape.CurveRenderer !== "undefined")
                        closeShape.preferredRendererType = Shape.CurveRenderer;
                }
                width: 15; height: 15
                antialiasing: true
                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                layer.samples: 4
                layer.smooth: true
                layer.textureSize: Qt.size(Math.ceil(lights.buttonDiameter * Screen.devicePixelRatio), Math.ceil(lights.buttonDiameter * Screen.devicePixelRatio))
                transform: Scale { xScale: closeButton.availableWidth / 15; yScale: closeButton.availableHeight / 15 }
                ShapePath {
                    strokeColor: "#7f2520"
                    strokeWidth: 1.2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M4 4 L11 11 M11 4 L4 11" }
                }
            }
        }
    }
    Basic.ToolButton {
        id: minimizeButton
        scale: down && !Theme.reducedMotion ? 0.90 : 1
        Behavior on scale { NumberAnimation { duration: minimizeButton.down ? Theme.pressDuration : Theme.releaseDuration; easing.type: Theme.motionEasing } }
        objectName: "windowMinimize"
        width: lights.buttonDiameter
        height: lights.buttonDiameter
        padding: 0
        hoverEnabled: true
        Accessible.name: qsTr("Minimize window")
        onClicked: lights.minimizeRequested()
        background: Rectangle {
            radius: width / 2
            antialiasing: true
            color: minimizeButton.down ? "#dca021" : lights.windowActive || lights.showSymbols ? "#febc2e" : lights.dark ? "#777779" : "#c5c5c7"
            border.width: 0.5
            border.color: lights.windowActive ? "#e5a41c" : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.colorDuration } }
        }
        contentItem: Item {
            visible: lights.showSymbols || minimizeButton.visualFocus
            Shape {
                id: minimizeShape
                Component.onCompleted: {
                    if ("preferredRendererType" in minimizeShape && typeof Shape.CurveRenderer !== "undefined")
                        minimizeShape.preferredRendererType = Shape.CurveRenderer;
                }
                width: 15; height: 15
                antialiasing: true
                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                layer.samples: 4
                layer.smooth: true
                layer.textureSize: Qt.size(Math.ceil(lights.buttonDiameter * Screen.devicePixelRatio), Math.ceil(lights.buttonDiameter * Screen.devicePixelRatio))
                transform: Scale { xScale: minimizeButton.availableWidth / 15; yScale: minimizeButton.availableHeight / 15 }
                ShapePath {
                    strokeColor: "#8d600c"
                    strokeWidth: 1.2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M3.8 7.5 L11.2 7.5" }
                }
            }
        }
    }
    Basic.ToolButton {
        id: zoomButton
        scale: down && !Theme.reducedMotion ? 0.90 : 1
        Behavior on scale { NumberAnimation { duration: zoomButton.down ? Theme.pressDuration : Theme.releaseDuration; easing.type: Theme.motionEasing } }
        objectName: "windowZoom"
        width: lights.buttonDiameter
        height: lights.buttonDiameter
        padding: 0
        hoverEnabled: true
        Accessible.name: qsTr("Maximize or restore window")
        onClicked: lights.zoomRequested()
        background: Rectangle {
            radius: width / 2
            antialiasing: true
            color: zoomButton.down ? "#1ba832" : lights.windowActive || lights.showSymbols ? "#28c840" : lights.dark ? "#777779" : "#c5c5c7"
            border.width: 0.5
            border.color: lights.windowActive ? "#19ac2c" : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.colorDuration } }
        }
        contentItem: Item {
            visible: lights.showSymbols || zoomButton.visualFocus
            Shape {
                id: zoomShape
                Component.onCompleted: {
                    if ("preferredRendererType" in zoomShape && typeof Shape.CurveRenderer !== "undefined")
                        zoomShape.preferredRendererType = Shape.CurveRenderer;
                }
                width: 15; height: 15
                antialiasing: true
                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                layer.samples: 4
                layer.smooth: true
                layer.textureSize: Qt.size(Math.ceil(lights.buttonDiameter * Screen.devicePixelRatio), Math.ceil(lights.buttonDiameter * Screen.devicePixelRatio))
                transform: Scale { xScale: zoomButton.availableWidth / 15; yScale: zoomButton.availableHeight / 15 }
                ShapePath {
                    strokeColor: "transparent"
                    strokeWidth: 1.2
                    fillColor: "#176c25"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M3.5 8 L8 3.5 L3.5 3.5 Z M11.5 7 L7 11.5 L11.5 11.5 Z" }
                }
            }
        }
    }
}
