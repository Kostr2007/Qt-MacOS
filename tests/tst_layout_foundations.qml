import QtQuick
import QtQuick.Controls.Basic as Basic
import QtTest
import QtMacOS

TestCase {
    id: testCase
    name: "LayoutFoundations"
    visible: true
    width: 640
    height: 600
    when: windowShown
    property bool previousDark

    Component {
        id: boxComponent
        MacBox {
            width: 340
            title: "Export options"
            MacLabel {
                objectName: "description"
                width: parent.width
                text: "Keep related controls together."
            }
        }
    }
    Component {
        id: disclosureComponent
        Item {
            width: 400
            height: 300
            MacDisclosureGroup {
                id: disclosure
                objectName: "disclosure"
                width: parent.width
                title: "Advanced export options"
                reducedMotion: true
                Basic.TextField {
                    objectName: "field"
                    width: parent.width
                    text: "Retained value"
                }
            }
            Basic.Button {
                objectName: "outside"
                y: 220
                text: "Outside"
            }
        }
    }
    Component {
        id: labelComponent
        MacLabel {
            width: 160
        }
    }

    function initTestCase() {
        failOnWarning(/.*/);
    }
    function init() {
        previousDark = Theme.dark;
    }
    function cleanup() {
        Theme.dark = previousDark;
    }
    function test_boxRespondsToContentAndWidth() {
        const box = createTemporaryObject(boxComponent, testCase);
        verify(box !== null);
        const description = findChild(box, "description");
        const shortHeight = box.implicitHeight;
        description.text = "A longer localized explanation remains readable when the window becomes narrower. The group grows with its contents instead of clipping the explanation.";
        tryVerify(function () {
            return box.implicitHeight > shortHeight;
        });
        const wideHeight = box.implicitHeight;
        box.width = 180;
        tryVerify(function () {
            return box.implicitHeight > wideHeight;
        });
        const titledHeight = box.implicitHeight;
        box.title = "";
        tryVerify(function () {
            return box.implicitHeight < titledHeight;
        });
    }
    function test_labelsWrapAndFollowAppearance() {
        const label = createTemporaryObject(labelComponent, testCase, {
            text: "A useful explanation can span several lines without being truncated."
        });
        verify(label !== null);
        const bodyHeight = label.implicitHeight;
        label.width = 80;
        tryVerify(function () {
            return label.implicitHeight > bodyHeight;
        });
        label.role = MacLabel.Secondary;
        Theme.dark = false;
        compare(label.color, Theme.secondary);
        Theme.dark = true;
        compare(label.color, Theme.secondary);
        label.role = MacLabel.Title;
        compare(label.color, Theme.text);
        verify(label.font.pixelSize > 13);
        compare(label.activeFocusOnTab, false);
    }
    function test_disclosurePointerAndKeyboardPreserveState() {
        const fixture = createTemporaryObject(disclosureComponent, testCase);
        const disclosure = findChild(fixture, "disclosure");
        const field = findChild(fixture, "field");
        const closedHeight = disclosure.implicitHeight;
        mouseClick(disclosure.header);
        tryCompare(disclosure, "expanded", true);
        verify(disclosure.implicitHeight > closedHeight);
        field.text = "Changed value";
        disclosure.header.forceActiveFocus();
        keyClick(Qt.Key_Space);
        tryCompare(disclosure, "expanded", false);
        compare(disclosure.implicitHeight, closedHeight);
        keyClick(Qt.Key_Return);
        tryCompare(disclosure, "expanded", true);
        compare(field.text, "Changed value");
        keyClick(Qt.Key_Enter);
        tryCompare(disclosure, "expanded", false);
    }
    function test_collapseReturnsOnlyHiddenFocusToHeader() {
        const fixture = createTemporaryObject(disclosureComponent, testCase);
        const disclosure = findChild(fixture, "disclosure");
        const field = findChild(fixture, "field");
        const outside = findChild(fixture, "outside");
        disclosure.expanded = true;
        field.forceActiveFocus();
        tryCompare(field, "activeFocus", true);
        disclosure.expanded = false;
        tryCompare(disclosure.header, "activeFocus", true);
        disclosure.expanded = true;
        outside.forceActiveFocus();
        disclosure.expanded = false;
        compare(outside.activeFocus, true);
    }
    function test_disabledDisclosureCannotToggle() {
        const fixture = createTemporaryObject(disclosureComponent, testCase);
        const disclosure = findChild(fixture, "disclosure");
        disclosure.enabled = false;
        mouseClick(disclosure.header);
        compare(disclosure.expanded, false);
    }
}
