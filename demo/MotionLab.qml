pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtMacOS

MacWindow {
    id: lab
    title: qsTr("Qt-MacOS Motion Lab")
    width: 1060; height: 850
    minimumWidth: 1000; minimumHeight: 800
    property real limit: 3
    property real frequency: 32
    property real deformationAmount: 0.10
    property int selectedMode: 2
    property string status: qsTr("Drag each profile, or replay the same motion in all three.")
    property bool recording: false
    property string recordingPath: ""
    property string outputDirectory: interactionRecorder.outputRoot
    property string presetPath: outputDirectory + "/preset.json"
    property var profiles: []
    Component.onCompleted: {
        Theme.dark = Qt.application.arguments.indexOf("--dark") >= 0;
        Theme.reducedMotion = Qt.application.arguments.indexOf("--reduce-motion") >= 0;
    }
    function preset() {
        return {schema: 1, mode: selectedMode, followLimit: limit,
                feedbackFrequency: frequency, deformation: deformationAmount};
    }
    function restorePreset() {
        const data = interactionRecorder.loadPreset(presetPath);
        if (data.schema !== 1 || !Number.isFinite(data.followLimit) || !Number.isFinite(data.feedbackFrequency)
            || !Number.isFinite(data.deformation) || !Number.isFinite(data.mode)) {
            status = qsTr("No valid saved preset."); return;
        }
        limit = Math.max(0, Math.min(8, data.followLimit));
        frequency = Math.max(16, Math.min(64, data.feedbackFrequency));
        deformationAmount = Math.max(0, Math.min(0.2, data.deformation));
        selectedMode = Math.max(0, Math.min(2, Math.round(data.mode)));
        status = qsTr("Preset loaded.");
    }
    function recordState() {
        const state = profiles.map(s => ({value: s.value, mode: s.motionMode, target: s.visualPosition,
            presented: s.presentedPosition, offset: s.presentationOffset, stretch: s.interactionStretch, pressed: s.pressed}));
        if (!interactionRecorder.sample({tag: "manual-lab", sliders: state})) endRecording();
    }
    function endRecording() {
        recording = false;
        const ok = interactionRecorder.stop();
        status = ok ? qsTr("Saved recording: ") + recordingPath : qsTr("Recording could not be saved.");
    }
    onClosing: {
        replay.stop();
        for (const slider of profiles) slider.pressed = false;
        if (recording) endRecording();
    }
    FrameAnimation {
        id: replay
        running: false
        onTriggered: {
            const t = elapsedTime;
            const target = t < 0.8 ? 0.2 + t * 0.8 : t < 1.6 ? 0.84 - (t - 0.8) * 0.9 : 0.12 + (t - 1.6) * 0.7;
            for (const slider of lab.profiles) slider.value = Math.max(0, Math.min(1, target));
            if (t >= 2.4) {
                stop();
                for (const slider of lab.profiles) slider.pressed = false;
            }
        }
    }
    Timer { interval: 33; repeat: true; running: lab.recording; onTriggered: lab.recordState() }
    WindowButtons {
        x: 22; y: 22
        dark: Theme.dark; windowActive: lab.active || lab.presentation
        onCloseRequested: lab.close()
        onMinimizeRequested: lab.showMinimized()
        onZoomRequested: lab.zoom()
    }
    ColumnLayout {
        x: 30; y: 65; width: parent.width - 60
        spacing: 14
        MacLabel { text: qsTr("Motion Lab"); role: MacLabel.Title }
        MacLabel { text: qsTr("Same input, three responses. Logical values update immediately."); role: MacLabel.Secondary }
        Repeater {
            model: [qsTr("Direct · baseline"), qsTr("Elastic · shape response"), qsTr("Soft follow · bounded offset + shape")]
            ColumnLayout {
                id: row
                required property int index
                required property string modelData
                Layout.fillWidth: true
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    MacLabel { text: row.modelData; Layout.fillWidth: true }
                    MacLabel { text: slider.value.toFixed(3) + "  |  " + slider.presentationOffset.toFixed(2) + qsTr(" px offset"); role: MacLabel.Caption }
                }
                MacSlider {
                    id: slider
                    objectName: "labSlider" + row.index
                    Layout.fillWidth: true
                    value: 0.25
                    motionMode: row.index
                    followLimit: lab.limit
                    feedbackFrequency: lab.frequency
                    deformation: lab.deformationAmount
                    Component.onCompleted: lab.profiles = lab.profiles.concat([slider])
                    Accessible.name: row.modelData
                }
            }
        }
        RowLayout {
            MacLabel { text: qsTr("Follow limit (px)"); Layout.preferredWidth: 175 }
            MacSlider { objectName: "labLimit"; Layout.fillWidth: true; minimumText: ""; maximumText: ""; tickCount: 0; from: 0; to: 8; stepSize: 0.5; motionMode: MacSlider.Direct; value: lab.limit; onMoved: lab.limit = value }
            MacLabel { text: lab.limit.toFixed(1); Layout.preferredWidth: 55 }
        }
        RowLayout {
            MacLabel { text: qsTr("Spring frequency"); Layout.preferredWidth: 175 }
            MacSlider { Layout.fillWidth: true; minimumText: ""; maximumText: ""; tickCount: 0; from: 16; to: 64; stepSize: 2; motionMode: MacSlider.Direct; value: lab.frequency; onMoved: lab.frequency = value }
            MacLabel { text: lab.frequency.toFixed(0); Layout.preferredWidth: 55 }
        }
        RowLayout {
            MacLabel { text: qsTr("Shape response"); Layout.preferredWidth: 175 }
            MacSlider { Layout.fillWidth: true; minimumText: ""; maximumText: ""; tickCount: 0; from: 0; to: 0.2; stepSize: 0.01; motionMode: MacSlider.Direct; value: lab.deformationAmount; onMoved: lab.deformationAmount = value }
            MacLabel { text: lab.deformationAmount.toFixed(2); Layout.preferredWidth: 55 }
        }
        RowLayout {
            MacPushButton {
                objectName: "labReplay"
                text: qsTr("Replay motion")
                enabled: !replay.running
                onClicked: {
                    for (const slider of lab.profiles) { slider.value = 0.2; slider.resetFeedback(); slider.pressed = true; }
                    replay.restart();
                }
            }
            MacPushButton {
                objectName: "labRecord"
                text: lab.recording ? qsTr("Stop recording") : qsTr("Record interaction")
                onClicked: {
                    if (lab.recording) { lab.endRecording(); return; }
                    lab.recordingPath = lab.outputDirectory + "/lab-" + Date.now();
                    lab.recording = interactionRecorder.start(lab.recordingPath, lab, true);
                    lab.status = lab.recording ? qsTr("Recording; frame capture can affect timing.") : qsTr("Could not start recording.");
                }
            }
            MacCheckBox { text: qsTr("Reduce Motion"); checked: Theme.reducedMotion; onToggled: Theme.reducedMotion = checked }
            MacCheckBox { text: qsTr("Dark"); checked: Theme.dark; onToggled: Theme.dark = checked }
        }
        RowLayout {
            MacLabel { text: qsTr("Preset profile"); role: MacLabel.Caption }
            MacPopupButton { objectName: "labProfile"; model: [qsTr("Direct"), qsTr("Elastic"), qsTr("Soft follow")]; currentIndex: lab.selectedMode; onActivated: lab.selectedMode = currentIndex }
            MacPushButton { objectName: "labSave"; text: qsTr("Save preset"); onClicked: lab.status = interactionRecorder.savePreset(lab.presetPath, lab.preset()) ? qsTr("Preset saved: ") + lab.presetPath : qsTr("Save failed.") }
            MacPushButton { objectName: "labLoad"; text: qsTr("Load preset"); onClicked: lab.restorePreset() }
        }
        MacLabel { Layout.fillWidth: true; text: lab.status; role: MacLabel.Caption; wrapMode: Text.Wrap }
    }
}
