pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.ComboBox {
    id: control
    implicitWidth: Math.max(150, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: 32
    leftPadding: 6
    rightPadding: 34
    hoverEnabled: true
    font.pixelSize: 17
    palette.window: Theme.dark ? "#3b3b3e" : "#fafafa"
    palette.base: Theme.field
    palette.text: Theme.settingsText
    palette.buttonText: Theme.settingsText
    palette.highlight: Theme.settingsAccent
    palette.highlightedText: "#ffffff"
    delegate: Basic.ItemDelegate {
        id: option
        required property int index
        objectName: "macPopupOption_" + index
        hoverEnabled: true
        width: control.popup.width - control.popup.leftPadding - control.popup.rightPadding
        text: control.textAt(index)
        highlighted: control.highlightedIndex === index
        font: control.font
        implicitHeight: 34
        padding: 10
        topPadding: 0
        bottomPadding: 0
        contentItem: Item {
            id: labelHost
            implicitHeight: label.implicitHeight
            Text {
                id: label
                anchors.fill: parent
                text: option.text
                font: option.font
                color: Theme.settingsText
                verticalAlignment: Text.AlignVCenter
            }
            // White glyphs follow the actual blue surface, rather than turning
            // white on the next row before the moving highlight reaches it.
            Item {
                id: whiteClip
                y: Math.max(0, selection.y - option.y - option.topPadding)
                width: parent.width
                height: Math.max(0, Math.min(parent.height,
                    selection.y + selection.height - option.y - option.topPadding) - y)
                clip: true
                visible: selection.visible
                Text {
                    y: -whiteClip.y
                    width: labelHost.width; height: labelHost.height
                    text: option.text; font: option.font
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        background: Item {}
    }
    popup: Basic.Popup {
        onAboutToShow: {
            options.positionInitialized = false;
        }
        onClosed: options.positionInitialized = false
        transformOrigin: Item.TopRight
        enter: MacPopupTransition {}
        exit: MacPopupTransition { appearing: false }
        y: control.height + 4
        width: control.width
        padding: 6
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
        contentItem: ListView {
            id: options
            objectName: "macPopupOptions"
            property bool positionInitialized: false
            property real selectionVelocity: 0
            readonly property real targetY: currentItem ? currentItem.y : selection.y
            function resetSelection() {
                if (!currentItem) return;
                selection.y = currentItem.y;
                selectionVelocity = 0;
                positionInitialized = control.popup.visible;
            }
            function updateSelection() {
                if (!positionInitialized || !control.popup.visible || Theme.reducedMotion)
                    resetSelection();
            }
            onCurrentItemChanged: updateSelection()
            onTargetYChanged: updateSelection()
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
            Rectangle {
                id: selection
                objectName: "macPopupSelection"
                parent: options.contentItem
                z: -1
                width: options.width
                height: options.currentItem ? options.currentItem.height : 34
                radius: 5
                color: Theme.settingsAccent
                visible: options.positionInitialized
                antialiasing: true
            }
            FrameAnimation {
                running: control.popup.visible && options.positionInitialized && !Theme.reducedMotion
                    && (Math.abs(selection.y - options.targetY) > 0.01 || Math.abs(options.selectionVelocity) > 0.1)
                onTriggered: {
                    const dt = Math.max(0.001, Math.min(0.05, frameTime || 1 / 60));
                    const frequency = 22;
                    const delta = selection.y - options.targetY;
                    const c = options.selectionVelocity + frequency * delta;
                    const decay = Math.exp(-frequency * dt);
                    selection.y = options.targetY + (delta + c * dt) * decay;
                    options.selectionVelocity = (options.selectionVelocity - frequency * c * dt) * decay;
                    if (Math.abs(selection.y - options.targetY) <= 0.01 && Math.abs(options.selectionVelocity) <= 0.1) {
                        selection.y = options.targetY;
                        options.selectionVelocity = 0;
                    }
                }
            }
            Connections {
                target: Theme
                function onReducedMotionChanged() { if (Theme.reducedMotion) options.resetSelection(); }
            }
        }
        background: Rectangle {
            radius: 9
            color: Theme.settingsGroup
            border.color: Theme.settingsSeparator
        }
    }
    contentItem: Text {
        text: control.displayText
        font: control.font
        color: control.enabled ? Theme.settingsText : Theme.settingsSecondary
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }
    indicator: Rectangle {
        x: control.width - width - 3
        y: (control.height - height) / 2
        width: 24
        height: 26
        radius: 7
        color: Theme.dark ? "#49494c" : control.hovered ? "#e5e5e7" : "#eeeef0"
        Behavior on color { ColorAnimation { duration: Theme.colorDuration } }
        opacity: control.enabled ? 1 : 0.45
        Canvas {
            anchors.centerIn: parent
            width: 12
            height: 16
            property color strokeColor: Theme.settingsText
            onStrokeColorChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.clearRect(0, 0, width, height);
                c.strokeStyle = strokeColor;
                c.lineWidth = 1.7;
                c.lineCap = "round";
                c.lineJoin = "round";
                c.beginPath();
                c.moveTo(3, 5);
                c.lineTo(6, 2);
                c.lineTo(9, 5);
                c.moveTo(3, 11);
                c.lineTo(6, 14);
                c.lineTo(9, 11);
                c.stroke();
            }
        }
    }
    background: Rectangle {
        radius: 5
        color: "transparent"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
    }
}
