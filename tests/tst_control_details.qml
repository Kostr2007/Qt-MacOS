import QtQuick
import QtQuick.Controls.Basic as Basic
import QtTest
import QtMacOS

Item {
    id: fixture
    width: 800; height: 580
    property real sliderValue: 0.45
    MacSlider {
        id: slider
        x: 20; y: 30; width: 330
        value: fixture.sliderValue
        onMoved: fixture.sliderValue = value
    }
    MacSlider {
        id: rtl
        x: 20; y: 120; width: 330
        LayoutMirroring.enabled: true
    }
    MacSlider {
        id: vertical
        x: 400; y: 20; height: 260
        orientation: Qt.Vertical
        minimumText: ""; maximumText: ""
    }
    Flickable {
        id: viewport
        x: 500; y: 20; width: 260; height: 400
        contentWidth: width; contentHeight: 1800
        Basic.ScrollBar.vertical: MacScrollBar { id: scroll; hideDelay: 80 }
    }
    WindowButtons { id: lights; x: 20; y: 240; buttonDiameter: 18 }
    SignalSpy { id: closeSpy; target: lights; signalName: "closeRequested" }
    TestCase {
        name: "ControlDetails"
        when: windowShown
        function initTestCase() { failOnWarning(/.*/) }
        function init() {
            Theme.reducedMotion = true
            viewport.cancelFlick()
            fixture.sliderValue = 0.45; rtl.value = 0.5; vertical.value = 0.5
            viewport.contentY = 0
            scroll.policy = Basic.ScrollBar.AsNeeded
            scroll.active = false
            mouseMove(fixture, 20, 540)
            closeSpy.clear()
            wait(150)
        }
        function cleanup() { Theme.reducedMotion = false }
        function handle(item) { return findChild(item, "macSliderHandle") }
        function fill(item) { return findChild(item, "macSliderFill") }
        function test_dragDoesNotQuantizeOrLagBehindBoundValue() {
            const thumb = handle(slider)
            verify(thumb.width > thumb.height)
            mousePress(slider, thumb.x + thumb.width / 2, 16)
            let previous = fixture.sliderValue
            for (let x = 170; x <= 210; x += 2) {
                mouseMove(slider, x, 16)
                verify(slider.pressed)
                verify(fixture.sliderValue > previous)
                previous = fixture.sliderValue
                verify(Math.abs(thumb.x + thumb.width / 2 - x) < 1)
                verify(Math.abs(fill(slider).width - thumb.x - thumb.width / 2) < 0.1)
            }
            mouseRelease(slider, 210, 16)
            compare(slider.value, fixture.sliderValue)
        }
        function test_keyboardFillAndThumbShareOneAnimatedPosition() {
            Theme.reducedMotion = false
            slider.forceActiveFocus()
            keyClick(Qt.Key_Right)
            const thumb = handle(slider)
            for (let i = 0; i < 8; ++i) {
                wait(16)
                verify(Math.abs(fill(slider).width - thumb.x - thumb.width / 2) < 0.1)
            }
            verify(fixture.sliderValue > 0.45)
        }
        function test_rtlAndVerticalFillFollowLogicalValue() {
            rtl.value = 0
            compare(handle(rtl).x, rtl.width - handle(rtl).width)
            compare(fill(rtl).width, handle(rtl).width / 2)
            rtl.value = 1
            compare(handle(rtl).x, 0)
            compare(fill(rtl).x, handle(rtl).width / 2)
            vertical.value = 0
            compare(handle(vertical).y, vertical.height - handle(vertical).height)
            compare(fill(vertical).height, handle(vertical).height / 2)
            vertical.value = 1
            compare(handle(vertical).y, 0)
            verify(fill(vertical).height > vertical.height / 2)
        }
        function test_overlayAppearsForActivityAndHidesAfterDelay() {
            compare(scroll.contentItem.opacity, 0)
            scroll.active = true
            compare(scroll.contentItem.opacity, 1)
            scroll.active = false
            compare(scroll.contentItem.opacity, 1)
            tryCompare(scroll.contentItem, "opacity", 0)
        }
        function test_realFlickAutomaticallyRevealsOverlay() {
            viewport.flick(0, -900)
            tryVerify(() => viewport.contentY > 0)
            tryCompare(scroll, "active", true)
            compare(scroll.contentItem.opacity, 1)
            viewport.cancelFlick()
            tryCompare(scroll, "active", false)
            tryCompare(scroll.contentItem, "opacity", 0)
        }
        function test_hoverAndDragRemainAvailableForHiddenOverlay() {
            mouseMove(scroll, scroll.width / 2, scroll.height / 2)
            tryCompare(scroll, "hovered", true)
            compare(scroll.contentItem.opacity, 1)
            const thumb = findChild(scroll, "macScrollThumb")
            compare(thumb.width, 7)
            mousePress(scroll, scroll.width / 2, thumb.parent.y + 10)
            mouseMove(scroll, scroll.width / 2, scroll.height * 0.75)
            verify(viewport.contentY > 0)
            mouseRelease(scroll, scroll.width / 2, scroll.height * 0.75)
        }
        function test_scrollBarPoliciesAndNoOverflow() {
            scroll.policy = Basic.ScrollBar.AlwaysOn
            compare(scroll.contentItem.opacity, 1)
            scroll.policy = Basic.ScrollBar.AlwaysOff
            compare(scroll.visible, false)
            scroll.policy = Basic.ScrollBar.AsNeeded
            viewport.contentHeight = viewport.height
            scroll.active = true
            tryCompare(scroll.contentItem, "opacity", 0)
            viewport.contentHeight = 1800
        }
        function test_vectorWindowButtonsStillActivateExactlyOnce() {
            const close = findChild(lights, "windowClose")
            compare(close.width, 18)
            compare(close.height, 18)
            mouseClick(close)
            compare(closeSpy.count, 1)
            close.forceActiveFocus()
            keyClick(Qt.Key_Space)
            compare(closeSpy.count, 2)
        }
    }
}
