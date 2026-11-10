pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Dialog {
    id: dialog
    modal: true
    focus: true
    property Item returnFocusItem: null
    onAboutToShow: returnFocusItem = parent && parent.Window.window ? parent.Window.window.activeFocusItem : null
    onClosed: {
        if (returnFocusItem && returnFocusItem.visible && returnFocusItem.enabled)
            returnFocusItem.forceActiveFocus(Qt.PopupFocusReason);
    }
    enter: MacPopupTransition {}
    exit: MacPopupTransition { appearing: false }
    Basic.Overlay.modal: Rectangle {
        color: "#40000000"
        Behavior on opacity { NumberAnimation { duration: Theme.colorDuration } }
    }
    padding: 22
    font.pixelSize: 16
    palette.windowText: Theme.settingsText
    palette.buttonText: Theme.settingsText
    background: Rectangle {
        radius: 14
        color: Theme.settingsGroup
        border.color: Theme.settingsSeparator
    }
    header: Text {
        text: dialog.title
        visible: text.length > 0
        color: Theme.settingsText
        font {
            family: dialog.font.family
            pixelSize: 19
            weight: Font.DemiBold
        }
        leftPadding: 22
        rightPadding: 22
        topPadding: 22
        bottomPadding: 0
        wrapMode: Text.Wrap
    }
    footer: Basic.DialogButtonBox {
        visible: count > 0
        alignment: Qt.AlignRight
        spacing: 10
        leftPadding: 22
        rightPadding: 22
        topPadding: 0
        bottomPadding: 18
        background: null
        delegate: MacPushButton {
            width: Math.max(80, implicitWidth)
            font: dialog.font
            highlighted: Basic.DialogButtonBox.buttonRole === Basic.DialogButtonBox.AcceptRole
        }
    }
}
