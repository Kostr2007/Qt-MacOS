pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import QtMacOS

Rectangle {
    id: sidebar
    property bool dark: true
    property bool windowActive: true
    property string selectedTitle: "Documents"
    signal navigate(string title)
    signal closeRequested
    signal minimizeRequested
    signal zoomRequested

    implicitWidth: 168
    color: dark ? "#48484a" : "#e8e8e9"
    readonly property color foreground: dark ? "#eeeeef" : "#262628"
    readonly property color secondary: dark ? "#939395" : "#858588"
    readonly property color selectedBackground: dark ? "#626264" : "#cfcfd2"

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: 12
        color: sidebar.color
    }

    WindowButtons {
        x: 24
        y: 24
        dark: sidebar.dark
        windowActive: sidebar.windowActive
        onCloseRequested: sidebar.closeRequested()
        onMinimizeRequested: sidebar.minimizeRequested()
        onZoomRequested: sidebar.zoomRequested()
    }

    Flickable {
        id: navigation
        anchors {
            fill: parent
            topMargin: 64
            bottomMargin: 8
        }
        contentWidth: width
        contentHeight: groups.height + 8
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: groups
            x: 12
            y: 8
            width: navigation.width - 24

            Text {
                x: 8
                height: 23
                text: qsTr("Favourites")
                color: sidebar.secondary
                font {
                    pixelSize: 14
                    weight: Font.DemiBold
                }
                verticalAlignment: Text.AlignTop
            }
            Repeater {
                model: [
                    {
                        title: "AirDrop",
                        symbol: "airdrop"
                    },
                    {
                        title: "Desktop",
                        symbol: "desktop"
                    },
                    {
                        title: "Applications",
                        symbol: "applications"
                    },
                    {
                        title: "Recents",
                        symbol: "recents"
                    },
                    {
                        title: "Documents",
                        symbol: "documents"
                    },
                    {
                        title: "Downloads",
                        symbol: "downloads"
                    }
                ]
                delegate: Basic.ItemDelegate {
                    id: navigationRow
                    required property var modelData
                    width: groups.width
                    height: 35
                    padding: 8
                    hoverEnabled: true
                    Accessible.name: modelData.title
                    highlighted: sidebar.selectedTitle === modelData.title
                    onClicked: sidebar.navigate(modelData.title)
                    background: MacSelectionBackground {
                        anchors { fill: parent; topMargin: 1; bottomMargin: 1 }
                        radius: 6
                        selected: navigationRow.highlighted
                        hovered: navigationRow.hovered
                        focused: navigationRow.visualFocus
                        selectionColor: sidebar.selectedBackground
                        hoverColor: sidebar.dark ? "#525254" : "#dedee0"
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        FinderIcon {
                            name: navigationRow.modelData.symbol
                            color: "#009aeb"
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                        }
                        Text {
                            text: navigationRow.modelData.title
                            color: sidebar.foreground
                            font.pixelSize: 17
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Item {
                width: 1
                height: 20
            }
            Text {
                x: 8
                height: 22
                text: qsTr("Locations")
                color: sidebar.secondary
                font {
                    pixelSize: 14
                    weight: Font.DemiBold
                }
            }
            Basic.ItemDelegate {
                id: cloudRow
                width: groups.width
                height: 35
                padding: 8
                hoverEnabled: true
                Accessible.name: qsTr("iCloud Drive")
                onClicked: sidebar.navigate("iCloud Drive")
                background: MacSelectionBackground {
                        radius: 6
                        selected: sidebar.selectedTitle === "iCloud Drive"
                        hovered: cloudRow.hovered
                        focused: cloudRow.visualFocus
                        selectionColor: sidebar.selectedBackground
                        hoverColor: sidebar.dark ? "#525254" : "#dedee0"
                    }
                contentItem: RowLayout {
                    spacing: 8
                    FinderIcon {
                        name: "cloud"
                        color: sidebar.secondary
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                    }
                    Text {
                        text: qsTr("iCloud Drive")
                        color: sidebar.foreground
                        font.pixelSize: 17
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
            Item {
                width: 1
                height: 20
            }
            Text {
                x: 8
                height: 22
                text: qsTr("Tags")
                color: sidebar.secondary
                font {
                    pixelSize: 14
                    weight: Font.DemiBold
                }
            }
            Repeater {
                model: [
                    {
                        title: "Red",
                        tint: "#ff555c"
                    },
                    {
                        title: "Orange",
                        tint: "#ffb125"
                    },
                    {
                        title: "Yellow",
                        tint: "#fff12d"
                    },
                    {
                        title: "Green",
                        tint: "#27e142"
                    },
                    {
                        title: "Blue",
                        tint: "#16a3f0"
                    },
                    {
                        title: "Purple",
                        tint: "#e986f4"
                    },
                    {
                        title: "Gray",
                        tint: "#a4a4ac"
                    }
                ]
                delegate: Basic.ItemDelegate {
                    id: tagRow
                    required property var modelData
                    width: groups.width
                    height: 35
                    padding: 8
                    hoverEnabled: true
                    Accessible.name: modelData.title + qsTr(" tag")
                    onClicked: sidebar.navigate(modelData.title)
                    background: MacSelectionBackground {
                        radius: 6
                        selected: sidebar.selectedTitle === tagRow.modelData.title
                        hovered: tagRow.hovered
                        focused: tagRow.visualFocus
                        selectionColor: sidebar.selectedBackground
                        hoverColor: sidebar.dark ? "#525254" : "#dedee0"
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Item {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            Rectangle {
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                radius: 6
                                color: tagRow.modelData.tint
                            }
                        }
                        Text {
                            text: tagRow.modelData.title
                            color: sidebar.foreground
                            font.pixelSize: 17
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
