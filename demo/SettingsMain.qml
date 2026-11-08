pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtMacOS

MacWindow {
    id: window
    width: 1048
    height: 910
    minimumWidth: 1000
    minimumHeight: 740
    normalRadius: 40
    surfaceObjectName: "preferencesFrame"
    surfaceColor: Theme.dark ? "#222225" : "#ffffff"
    title: pageTitle + " — Qt-MacOS Settings"
    readonly property var sections: [
        {
            key: "Notifications",
            icon: "notification",
            tint: "#f34657"
        },
        {
            key: "Sound",
            icon: "sound",
            tint: "#ee4266"
        },
        {
            key: "Focus",
            icon: "focus",
            tint: "#7756dd"
        },
        {
            key: "Screen Time",
            icon: "screentime",
            tint: "#8257d8"
        },
        {
            key: "Lock Screen",
            icon: "lock",
            tint: "#27292c",
            gap: true
        },
        {
            key: "Privacy & Security",
            icon: "privacy",
            tint: "#4aa9ee"
        },
        {
            key: "Login Password",
            icon: "password",
            tint: "#999c9d"
        },
        {
            key: "Users & Groups",
            icon: "users",
            tint: "#208bd3"
        },
        {
            key: "Internet Accounts",
            icon: "internet",
            tint: "#319ccc",
            gap: true
        },
        {
            key: "Game Center",
            icon: "game",
            tint: "#f5f5f6"
        },
        {
            key: "iCloud",
            icon: "cloud",
            tint: "#66c3eb"
        },
        {
            key: "Wallet & Apple Pay",
            icon: "wallet",
            tint: "#303232"
        },
        {
            key: "Keyboard",
            icon: "keyboard",
            tint: "#a1a5a4",
            gap: true
        },
        {
            key: "Mouse",
            icon: "mouse",
            tint: "#a1a5a4"
        },
        {
            key: "Printers & Scanners",
            icon: "printer",
            tint: "#a1a5a4"
        }
    ]
    property string pageTitle: "Mouse"
    property var history: ["Settings", "Mouse"]
    property int historyIndex: 1
    property real trackingSpeed: 0.45
    property real doubleClickSpeed: 0.79
    property real scrollingSpeed: 0.56
    property bool naturalScrolling: false
    property int secondaryClick: 0
    property bool pointerAcceleration: true
    readonly property color foreground: Theme.settingsText
    function navigate(page) {
        if (page === pageTitle)
            return;
        history = history.slice(0, historyIndex + 1).concat([page]);
        historyIndex = history.length - 1;
        pageTitle = page;
    }
    function resetPreferences() {
        trackingSpeed = 0.45;
        doubleClickSpeed = 0.79;
        scrollingSpeed = 0.56;
        naturalScrolling = false;
        secondaryClick = 0;
        pointerAcceleration = true;
    }
    Component.onCompleted: {
        const args = Qt.application.arguments;
        Theme.dark = args.indexOf("--dark") >= 0;
        naturalScrolling = args.indexOf("--natural-on") >= 0;
        if (args.indexOf("--advanced") >= 0)
            Qt.callLater(() => advanced.open());
        if (args.indexOf("--secondary-menu") >= 0)
            Qt.callLater(() => secondary.popup.open());
    }

    Shortcut {
        sequence: StandardKey.Find
        onActivated: navigation.focusSearch()
    }
    Shortcut {
        sequence: "Ctrl+Shift+L"
        onActivated: Theme.dark = !Theme.dark
    }

    SettingsSidebar {
        id: navigation
        entries: window.sections
        objectName: "preferencesSidebar"
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            margins: 1
        }
        width: 306
        radius: Math.max(0, window.corner - 1)
        dark: Theme.dark
        fontFamily: window.font.family
        currentKey: window.pageTitle
        onNavigate: key => window.navigate(key)
    }
    WindowButtons {
        x: 26
        y: 27
        scale: 1.25
        transformOrigin: Item.TopLeft
        dark: Theme.dark
        windowActive: window.active || window.presentation
        onCloseRequested: window.close()
        onMinimizeRequested: window.showMinimized()
        onZoomRequested: window.zoom()
    }
    Item {
        id: header
        x: navigation.width + 1
        y: 1
        width: parent.width - x - 1
        height: 74
        MouseArea {
            anchors.fill: parent
            onPressed: window.startSystemMove()
            onDoubleClicked: window.zoom()
        }
        Rectangle {
            x: 12
            y: 12
            width: 92
            height: 50
            radius: 20
            color: Theme.dark ? "#303034" : "#fafafa"
            Row {
                anchors.centerIn: parent
                FinderToolButton {
                    objectName: "preferencesBack"
                    symbol: "back"
                    text: qsTr("Back")
                    glyphColor: Theme.dark ? "#b4b4b8" : "#65656a"
                    enabled: window.historyIndex > 0
                    onClicked: {
                        --window.historyIndex;
                        window.pageTitle = window.history[window.historyIndex];
                    }
                }
                FinderToolButton {
                    objectName: "preferencesForward"
                    symbol: "forward"
                    text: qsTr("Forward")
                    glyphColor: Theme.dark ? "#b4b4b8" : "#65656a"
                    enabled: window.historyIndex < window.history.length - 1
                    onClicked: {
                        ++window.historyIndex;
                        window.pageTitle = window.history[window.historyIndex];
                    }
                }
            }
        }
        Text {
            x: 128
            anchors.verticalCenter: parent.verticalCenter
            text: window.pageTitle
            color: window.foreground
            font {
                family: window.font.family
                pixelSize: 20
                weight: Font.DemiBold
            }
        }
    }
    Flickable {
        id: page
        x: navigation.width + 1
        y: header.height + 1
        width: parent.width - x - 1
        height: parent.height - y - 1
        clip: true
        contentWidth: width
        contentHeight: mouseContent.height + 24
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: MacScrollBar {}
        Column {
            id: mouseContent
            x: 26
            y: 0
            width: page.width - 52
            spacing: 28
            visible: window.pageTitle === "Mouse"
            SettingsGroup {
                width: parent.width
                horizontalPadding: 12
                verticalPadding: 0
                SettingsRow {
                    title: qsTr("Tracking speed")
                    fontFamily: window.font.family
                    controlWidth: 332
                    rowHeight: 66
                    labelOffset: -11
                    MacSlider {
                        id: tracking
                        objectName: "trackingSlider"
                        width: parent.width
                        font.family: window.font.family
                        value: window.trackingSpeed
                        onMoved: window.trackingSpeed = value
                        Accessible.name: qsTr("Tracking speed")
                    }
                }
                SettingsRow {
                    title: qsTr("Natural scrolling")
                    description: qsTr("Content tracks finger movement")
                    fontFamily: window.font.family
                    controlWidth: 70
                    rowHeight: 74
                    controlOffset: -11
                    MacSwitch {
                        id: natural
                        objectName: "naturalSwitch"
                        anchors.right: parent.right
                        checked: window.naturalScrolling
                        onToggled: window.naturalScrolling = checked
                        Accessible.name: qsTr("Natural scrolling")
                    }
                }
                SettingsRow {
                    title: qsTr("Secondary click")
                    fontFamily: window.font.family
                    controlWidth: 250
                    rowHeight: 56
                    MacPopupButton {
                        id: secondary
                        objectName: "secondaryPopup"
                        width: parent.width
                        font.family: window.font.family
                        model: [qsTr("Click Right Side"), qsTr("Click Left Side"), qsTr("Off")]
                        currentIndex: window.secondaryClick
                        onActivated: window.secondaryClick = currentIndex
                        Accessible.name: qsTr("Secondary click")
                    }
                }
                SettingsRow {
                    title: qsTr("Double-Click Speed")
                    fontFamily: window.font.family
                    controlWidth: 332
                    rowHeight: 68
                    labelOffset: -11
                    MacSlider {
                        objectName: "doubleClickSlider"
                        width: parent.width
                        font.family: window.font.family
                        value: window.doubleClickSpeed
                        onMoved: window.doubleClickSpeed = value
                        Accessible.name: qsTr("Double-Click Speed")
                    }
                }
                SettingsRow {
                    title: qsTr("Scrolling Speed")
                    fontFamily: window.font.family
                    controlWidth: 332
                    rowHeight: 68
                    labelOffset: -11
                    separator: false
                    MacSlider {
                        objectName: "scrollingSlider"
                        width: parent.width
                        font.family: window.font.family
                        value: window.scrollingSpeed
                        onMoved: window.scrollingSpeed = value
                        Accessible.name: qsTr("Scrolling Speed")
                    }
                }
            }
            RowLayout {
                width: parent.width
                spacing: 14
                Item {
                    Layout.fillWidth: true
                }
                MacPushButton {
                    id: advancedButton
                    objectName: "advancedButton"
                    text: qsTr("Advanced…")
                    font.family: window.font.family
                    implicitWidth: 130
                    onClicked: advanced.open()
                }
                MacPushButton {
                    id: bluetoothButton
                    objectName: "bluetoothButton"
                    text: qsTr("Set Up Bluetooth Mouse…")
                    font.family: window.font.family
                    implicitWidth: 250
                    onClicked: bluetooth.open()
                }
                MacHelpButton {
                    id: helpButton
                    objectName: "helpButton"
                    text: "?"
                    font.family: window.font.family
                    implicitWidth: 32
                    onClicked: help.open()
                    Accessible.name: qsTr("Mouse settings help")
                }
            }
        }
        Column {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 100
            }
            spacing: 20
            visible: window.pageTitle !== "Mouse"
            Text {
                text: qsTr("This sample implements the Mouse page.")
                color: Theme.settingsSecondary
                font.family: window.font.family
                font.pixelSize: 16
            }
            MacPushButton {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Return to Mouse")
                onClicked: window.navigate("Mouse")
            }
        }
    }
    MacDialog {
        id: advanced
        objectName: "advancedDialog"
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 460
        title: qsTr("Advanced mouse settings")
        standardButtons: Dialog.Ok | Dialog.Reset
        palette.window: Theme.settingsGroup
        palette.windowText: window.foreground
        palette.buttonText: window.foreground

        contentItem: ColumnLayout {
            spacing: 18
            Text {
                text: qsTr("These preferences affect this demo only.")
                color: Theme.settingsSecondary
                font.family: window.font.family
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
            RowLayout {
                Text {
                    text: qsTr("Pointer acceleration")
                    color: window.foreground
                    font.family: window.font.family
                    Layout.fillWidth: true
                }
                MacSwitch {
                    objectName: "accelerationSwitch"
                    checked: window.pointerAcceleration
                    onToggled: window.pointerAcceleration = checked
                    Accessible.name: qsTr("Pointer acceleration")
                }
            }
        }
        onReset: window.resetPreferences()
        onClosed: advancedButton.forceActiveFocus()
    }
    MacDialog {
        id: bluetooth
        objectName: "bluetoothDialog"
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 460
        title: qsTr("Bluetooth mouse")
        onClosed: bluetoothButton.forceActiveFocus()
        standardButtons: Dialog.Close
        contentItem: Text {
            text: qsTr("This is a UI demonstration. It does not scan, pair devices or change Linux mouse settings.")
            wrapMode: Text.Wrap
            color: window.foreground
            font.family: window.font.family
        }
    }
    Popup {
        id: help
        focus: true
        onClosed: helpButton.forceActiveFocus()
        objectName: "mouseHelp"
        parent: Overlay.overlay
        x: window.width - width - window.frameMargin - 24
        y: window.frameMargin + 470
        width: 320
        padding: 18
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            radius: 12
            color: Theme.settingsGroup
            border.color: Theme.settingsSeparator
        }
        contentItem: Text {
            text: qsTr("Drag a slider or use arrow keys. Changes stay in this demo. Advanced → Reset restores defaults.")
            wrapMode: Text.Wrap
            color: window.foreground
            font.family: window.font.family
            font.pixelSize: 15
        }
    }
}
