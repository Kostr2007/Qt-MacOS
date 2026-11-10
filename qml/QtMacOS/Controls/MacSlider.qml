pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Slider {
    id: control
    property string minimumText: qsTr("Slow")
    property string maximumText: qsTr("Fast")
    property int tickCount: 11
    enum MotionMode { Direct, Elastic, SoftFollow }
    property int motionMode: MacSlider.SoftFollow
    // Qt adaptation tuning, not Apple constants. Value changes remain exact;
    // only the presentation has bounded displacement and velocity-based shape.
    property real followLimit: 3
    property real feedbackFrequency: 32
    property real deformation: 0.10
    readonly property real axisTravel: Math.max(0, horizontal ? availableWidth - thumbWidth : availableHeight - thumbHeight)
    readonly property real presentedPosition: axisTravel > 0
        ? Math.max(0, Math.min(axisTravel, motion.position * axisTravel + (motionMode === MacSlider.SoftFollow ? motion.offset : 0))) / axisTravel : 0
    readonly property real presentationOffset: (presentedPosition - motion.position) * axisTravel
    readonly property real interactionStretch: Theme.reducedMotion || motionMode === MacSlider.Direct ? 0 : motion.stretch
    // The pointer moves the thumb directly. Keyboard/programmatic changes share
    // one interpolated position, so the fill can never lag behind the thumb.
    readonly property real thumbWidth: horizontal ? 28 : 22
    readonly property real thumbHeight: horizontal ? 22 : 28
    readonly property bool hasCaptions: horizontal && (minimumText.length > 0 || maximumText.length > 0)
    implicitWidth: horizontal ? 300 : 36
    implicitHeight: horizontal ? (hasCaptions ? 54 : 32) : 180
    padding: 0
    bottomPadding: hasCaptions ? 22 : 0
    hoverEnabled: true
    live: true
    snapMode: Basic.Slider.NoSnap
    Accessible.name: qsTr("Value")
    function resetFeedback() {
        if (!motion) return;
        motion.offset = 0; motion.velocity = 0;
        motion.stretch = 0; motion.stretchVelocity = 0;
        motion.lastTarget = visualPosition * axisTravel;
    }
    // Exact critically damped step: continuous velocity when a target reverses,
    // stable at different refresh rates, no Euler integration or fixed timer.
    function springStep(value, velocity, target, seconds) {
        const frequency = Math.max(4, Math.min(80, feedbackFrequency));
        const delta = value - target;
        const c = velocity + frequency * delta;
        const decay = Math.exp(-frequency * seconds);
        return [target + (delta + c * seconds) * decay,
                (velocity - frequency * c * seconds) * decay];
    }
    onMotionModeChanged: resetFeedback()
    onAxisTravelChanged: resetFeedback()
    onPressedChanged: {
        if (pressed) motion.lastTarget = visualPosition * axisTravel;
    }
    Connections {
        target: Theme
        function onReducedMotionChanged() { if (Theme.reducedMotion) control.resetFeedback(); }
    }
    FrameAnimation {
        running: !Theme.reducedMotion && control.motionMode !== MacSlider.Direct
            && (control.pressed || Math.abs(motion.offset) > 0.001 || Math.abs(motion.velocity) > 0.01
                || motion.stretch > 0.0001 || Math.abs(motion.stretchVelocity) > 0.001)
        onTriggered: {
            const dt = Math.max(0.001, Math.min(0.05, frameTime || 1 / 60));
            const target = control.visualPosition * control.axisTravel;
            const speed = (target - motion.lastTarget) / dt;
            motion.lastTarget = target;
            const limit = Math.max(0, Math.min(8, control.followLimit));
            const desiredOffset = control.pressed && control.motionMode === MacSlider.SoftFollow
                ? Math.max(-limit, Math.min(limit, -speed * 0.004)) : 0;
            const offset = control.springStep(motion.offset, motion.velocity, desiredOffset, dt);
            motion.offset = Math.max(-limit, Math.min(limit, offset[0]));
            motion.velocity = offset[1];
            const desiredStretch = control.pressed ? 0.03 + Math.min(1, Math.abs(speed) / 1200) * Math.max(0, Math.min(0.2, control.deformation)) : 0;
            const shape = control.springStep(motion.stretch, motion.stretchVelocity, desiredStretch, dt);
            motion.stretch = Math.max(0, Math.min(0.23, shape[0]));
            motion.stretchVelocity = shape[1];
            if (!control.pressed && Math.abs(motion.offset) < 0.001 && Math.abs(motion.velocity) < 0.01
                && motion.stretch < 0.0001 && Math.abs(motion.stretchVelocity) < 0.001)
                control.resetFeedback();
        }
    }
    QtObject {
        id: motion
        property real offset: 0
        property real velocity: 0
        property real stretch: 0
        property real stretchVelocity: 0
        property real lastTarget: 0
        property real position: control.visualPosition
        Behavior on position {
            enabled: !control.pressed
            NumberAnimation { duration: Theme.colorDuration; easing.type: Theme.motionEasing }
        }
    }
    background: Item {
        x: control.leftPadding
        y: control.topPadding
        implicitWidth: control.horizontal ? 300 : 36
        implicitHeight: control.horizontal ? 34 : 180
        width: control.availableWidth
        height: control.availableHeight
        opacity: control.enabled ? 1 : 0.45
        Rectangle {
            id: track
            x: control.horizontal ? 0 : (parent.width - width) / 2
            y: control.horizontal ? (parent.height - height) / 2 : 0
            width: control.horizontal ? parent.width : 6
            height: control.horizontal ? 6 : parent.height
            radius: 3
            antialiasing: true
            color: Theme.dark ? "#57575b" : "#e2e2e4"
            Rectangle {
                objectName: "macSliderFill"
                readonly property real center: control.horizontal
                    ? control.thumbWidth / 2 + control.presentedPosition * (control.availableWidth - control.thumbWidth)
                    : control.thumbHeight / 2 + control.presentedPosition * (control.availableHeight - control.thumbHeight)
                x: control.horizontal && control.mirrored ? center : 0
                width: control.horizontal ? (control.mirrored ? parent.width - center : center) : parent.width
                height: control.horizontal ? parent.height : parent.height - center
                anchors.bottom: control.horizontal ? undefined : parent.bottom
                radius: parent.radius
                antialiasing: true
                color: Theme.settingsAccent
            }
        }
        Repeater {
            model: control.horizontal ? Math.max(0, control.tickCount) : 0
            Rectangle {
                required property int index
                x: control.thumbWidth / 2 + index * (control.availableWidth - control.thumbWidth) / Math.max(1, control.tickCount - 1) - 1
                y: control.availableHeight / 2 + 9
                width: 2
                height: 2
                radius: 1
                color: Theme.dark ? "#77777b" : "#c4c4c8"
            }
        }
        Text {
            y: parent.height + 1
            visible: control.hasCaptions
            text: control.minimumText
            font {
                family: control.font.family
                pixelSize: 13
            }
            color: Theme.settingsSecondary
        }
        Text {
            anchors.right: parent.right
            y: parent.height + 1
            visible: control.hasCaptions
            text: control.maximumText
            font {
                family: control.font.family
                pixelSize: 13
            }
            color: Theme.settingsSecondary
        }
    }
    handle: Rectangle {
        objectName: "macSliderHandle"
        x: control.leftPadding + (control.horizontal ? control.presentedPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : control.presentedPosition * (control.availableHeight - height))
        implicitWidth: control.thumbWidth
        implicitHeight: control.thumbHeight
        radius: Math.min(width, height) / 2
        antialiasing: true
        color: control.pressed ? "#f8f8f8" : "#ffffff"
        border.width: control.visualFocus ? 2 : 0.5
        border.color: control.visualFocus ? Theme.accent : "#e9e9eb"
        opacity: control.enabled ? 1 : 0.55
        scale: control.pressed && !Theme.reducedMotion ? 1.03 : 1
        Behavior on scale { NumberAnimation { duration: Theme.pressDuration; easing.type: Theme.motionEasing } }
        transform: Scale {
            origin.x: control.thumbWidth / 2; origin.y: control.thumbHeight / 2
            xScale: control.horizontal ? 1 + control.interactionStretch : 1 - control.interactionStretch * 0.25
            yScale: control.horizontal ? 1 - control.interactionStretch * 0.25 : 1 + control.interactionStretch
        }
        Rectangle {
            z: -1
            x: -1
            y: 1
            width: parent.width + 2
            height: parent.height + 2
            radius: Math.min(width, height) / 2
            antialiasing: true
            color: "#16000000"
        }
    }
}
