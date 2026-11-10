import QtQuick
import QtQuick.Controls.Basic as Basic
import QtTest
import QtMacOS
import "../demo" as Demo

Rectangle {
    id: fixture
    width: 860; height: 600
    color: Theme.dark ? "#30383d" : "#f0fafd"
    property real backendValue: 0.25
    Basic.ItemDelegate {
        id: row
        x: 30; y: 20; width: 220; height: 44
        hoverEnabled: true
        background: MacSelectionBackground {
            id: surface
            hovered: row.hovered
            selected: row.highlighted
            selectionColor: "#0067d8"
            hoverColor: Theme.dark ? "#454f56" : "#e0ebee"
        }
    }
    MacSlider {
        id: slider; x: 30; y: 130; width: 480
        value: fixture.backendValue
        onMoved: fixture.backendValue = value
    }
    SignalSpy { id: moved; target: slider; signalName: "moved" }
    Component { id: labComponent; Demo.MotionLab {} }
    TestCase {
        name: "InteractionQuality"
        when: windowShown
        function initTestCase() { failOnWarning(/.*/) }
        function init() {
            Theme.reducedMotion = true; Theme.dark = false
            row.highlighted = false
            slider.motionMode = MacSlider.SoftFollow
            fixture.backendValue = 0.25; slider.followLimit = 3; slider.enabled = true
            slider.resetFeedback()
            mouseMove(fixture, 800, 550)
            wait(20)
            moved.clear()
            Theme.reducedMotion = false
        }
        function cleanup() {
            mouseRelease(fixture, 800, 550)
            Theme.reducedMotion = true; slider.resetFeedback()
        }
        function luma() {
            const image = grabImage(fixture)
            return (.2126 * image.red(210, 40) + .7152 * image.green(210, 40) + .0722 * image.blue(210, 40)) / 255
        }
        function test_hoverHasNoIntermediateDarkFlash_data() {
            return [{tag: "light", dark: false}, {tag: "dark", dark: true}]
        }
        function test_hoverHasNoIntermediateDarkFlash(data) {
            Theme.dark = data.dark
            mouseMove(fixture, 800, 550); wait(160)
            const rest = luma()
            mouseMove(row, 180, 22); wait(160)
            const full = luma()
            mouseMove(fixture, 800, 550); wait(160)
            mouseMove(row, 180, 22)
            for (let n = 0; n < 10; ++n) {
                wait(16)
                const brightness = luma()
                verify(brightness >= Math.min(rest, full) - .012, "Hover dipped below both endpoints")
                verify(brightness <= Math.max(rest, full) + .012, "Hover exceeded both endpoints")
            }
        }
        function test_selectionStaysBlueDuringInterruptedHover() {
            mouseMove(row, 180, 22); wait(32)
            row.highlighted = true
            for (let n = 0; n < 6; ++n) {
                mouseMove(n % 2 ? row : fixture, n % 2 ? 180 : 800, n % 2 ? 22 : 550)
                wait(16)
                const image = grabImage(fixture)
                compare(image.red(210, 40), 0)
                compare(image.blue(210, 40), 216)
            }
        }
        function test_softFollowIsBoundedAndReleaseDoesNotChangeValue() {
            mousePress(slider, slider.handle.x + slider.handle.width / 2, 16)
            let peak = 0
            for (const x of [220, 280, 360, 410, 330, 250, 150, 90, 180, 280, 370]) {
                mouseMove(slider, x, 16); wait(20)
                peak = Math.max(peak, Math.abs(slider.presentationOffset))
                verify(Math.abs(slider.presentationOffset) <= slider.followLimit + .001)
                const fill = findChild(slider, "macSliderFill")
                verify(Math.abs(fill.width - slider.handle.x - slider.handle.width / 2) < .1)
            }
            verify(peak > .1, "Soft profile should differ from rigid tracking")
            const value = slider.value
            mouseRelease(slider, 370, 16)
            const changes = moved.count
            tryCompare(slider, "presentationOffset", 0)
            tryCompare(slider, "interactionStretch", 0)
            compare(slider.value, value)
            compare(fixture.backendValue, value)
            compare(moved.count, changes)
        }
        function test_elasticModeChangesShapeWithoutMovingValue() {
            slider.motionMode = MacSlider.Elastic
            mousePress(slider, slider.handle.x + slider.handle.width / 2, 16)
            mouseMove(slider, 380, 16)
            compare(slider.pressed, true)
            compare(slider.presentationOffset, 0)
            tryVerify(() => slider.interactionStretch > .01)
            mouseRelease(slider, 380, 16)
            tryCompare(slider, "interactionStretch", 0)
        }
        function test_reducedMotionInterruptsActiveSpringImmediately() {
            mousePress(slider, slider.handle.x + slider.handle.width / 2, 16)
            mouseMove(slider, 400, 16)
            tryVerify(() => slider.interactionStretch > .01)
            Theme.reducedMotion = true
            compare(slider.presentationOffset, 0)
            compare(slider.interactionStretch, 0)
            const value = slider.value
            mouseRelease(slider, 400, 16)
            compare(slider.value, value)
        }
        function test_directModeAndBoundsRemainExact() {
            slider.motionMode = MacSlider.Direct
            mousePress(slider, slider.handle.x + slider.handle.width / 2, 16)
            mouseMove(slider, 900, 16)
            compare(slider.value, 1)
            compare(slider.presentationOffset, 0)
            compare(slider.interactionStretch, 0)
            mouseMove(slider, -100, 16)
            compare(slider.value, 0)
            mouseRelease(slider, -100, 16)
        }
        function test_regrabDuringSettlingPreservesCurrentValue() {
            mousePress(slider, slider.handle.x + slider.handle.width / 2, 16)
            mouseMove(slider, 390, 16); wait(30)
            mouseRelease(slider, 390, 16)
            const value = slider.value
            mousePress(slider, slider.handle.x + slider.handle.width / 2, 16)
            verify(Math.abs(slider.value - value) < .001)
            mouseRelease(slider, slider.handle.x + slider.handle.width / 2, 16)
        }
        function test_labReplayPresetAndRecorderRoundTrip() {
            const lab = createTemporaryObject(labComponent, null)
            verify(lab)
            lab.outputDirectory = interactionTestDirectory + "/lab-" + Date.now()
            verify(waitForRendering(lab.contentItem))
            lab.limit = 4.5
            mouseClick(findChild(lab, "labSave"))
            lab.limit = 1
            mouseClick(findChild(lab, "labLoad"))
            compare(lab.limit, 4.5)
            mouseClick(findChild(lab, "labRecord"))
            compare(lab.recording, true)
            mouseClick(findChild(lab, "labReplay"))
            wait(180)
            const path = lab.recordingPath
            mouseClick(findChild(lab, "labRecord"))
            compare(lab.recording, false)
            const trace = interactionRecorder.loadPreset(path + "/trace.json")
            compare(trace.schema, 1)
            verify(trace.samples.length > 0)
            verify(trace.samples[0].file.length > 0)
            lab.close()
        }
    }
}
