pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtMacOS

Rectangle {
    id: browser
    property string query: ""
    property string category: "Documents"
    property string fontFamily: "sans-serif"
    property bool gridMode: false
    property bool ascending: true
    property bool transparentBackground: false
    property string selectedName: ""
    readonly property color foreground: Theme.dark ? "#e5e5e7" : "#28282a"
    readonly property color secondary: Theme.dark ? "#a4a4a7" : "#737377"
    readonly property color stripe: Theme.dark ? "#2e2f31" : "#f0f0f2"
    readonly property color separator: Theme.dark ? "#444447" : "#d0d0d3"
    readonly property int headerHeight: 34
    readonly property int rowHeight: 26
    readonly property real nameWidth: width * 0.435
    readonly property real dateWidth: width * 0.25
    readonly property real sizeWidth: width * 0.135
    readonly property real kindWidth: width - nameWidth - dateWidth - sizeWidth
    readonly property int resultCount: visibleFiles.length
    readonly property var files: [
        {
            name: "SCR-20231030-nrrr.png",
            kind: "PNG image",
            size: "1,4 MB",
            date: "30 October 2023, 15:29",
            preview: 0,
            tag: "Red"
        },
        {
            name: "SCR-20231030-nsra.jpeg",
            kind: "JPEG image",
            size: "293 KB",
            date: "30 October 2023, 15:31",
            preview: 1,
            tag: "Orange"
        },
        {
            name: "SCR-20231030-nsxx.jpeg",
            kind: "JPEG image",
            size: "541 KB",
            date: "30 October 2023, 15:33",
            preview: 2,
            tag: "Yellow"
        },
        {
            name: "SCR-20231030-ntqh.jpeg",
            kind: "JPEG image",
            size: "262 KB",
            date: "30 October 2023, 15:34",
            preview: 3,
            tag: "Green"
        },
        {
            name: "SCR-20231030-ntze.jpeg",
            kind: "JPEG image",
            size: "298 KB",
            date: "30 October 2023, 15:35",
            preview: 4,
            tag: "Blue"
        },
        {
            name: "SCR-20231030-nwcc.jpeg",
            kind: "JPEG image",
            size: "293 KB",
            date: "30 October 2023, 15:46",
            preview: 5,
            tag: "Purple"
        },
        {
            name: "SCR-20231107-pdqy.jpeg",
            kind: "JPEG image",
            size: "1,2 MB",
            date: "Today, 17:19",
            preview: 6,
            tag: "Gray"
        },
        {
            name: "SCR-20231107-pgrj.png",
            kind: "PNG image",
            size: "1,9 MB",
            date: "Today, 17:24",
            preview: 7,
            tag: "Red"
        },
        {
            name: "SCR-20231107-pnii.jpeg",
            kind: "JPEG image",
            size: "304 KB",
            date: "Today, 17:42",
            preview: 8,
            tag: "Blue"
        }
    ]
    readonly property var visibleFiles: {
        const term = query.trim().toLocaleLowerCase();
        const tags = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Gray"];
        return files.filter(f => (!term || f.name.toLocaleLowerCase().includes(term)) && (!tags.includes(category) || f.tag === category) && (!["AirDrop", "Applications", "iCloud Drive"].includes(category)) && (category !== "Downloads" || f.preview >= 6) && (category !== "Desktop" || f.kind === "PNG image")).sort((a, b) => (ascending ? 1 : -1) * a.name.localeCompare(b.name));
    }
    function selectIndex(index) {
        if (index >= 0 && index < resultCount)
            selectedName = visibleFiles[index].name;
    }
    onCategoryChanged: {
        selectedName = "";
        list.currentIndex = -1;
        grid.currentIndex = -1;
    }
    onQueryChanged: {
        selectedName = "";
        list.currentIndex = -1;
        grid.currentIndex = -1;
    }
    color: transparentBackground ? "transparent" : Theme.dark ? "#252628" : "#ffffff"
    clip: true

    // Header and rows share the same column metrics, rather than independent layouts.
    Item {
        width: parent.width
        height: browser.headerHeight
        visible: !browser.gridMode
        Text {
            x: 60
            height: parent.height
            text: qsTr("Name")
            color: browser.foreground
            font {
                family: browser.fontFamily
                pixelSize: 15
                weight: Font.DemiBold
            }
            verticalAlignment: Text.AlignVCenter
        }
        FinderIcon {
            x: browser.nameWidth - 20
            y: 10
            width: 12
            height: 12
            name: "chevron"
            color: browser.secondary
            rotation: browser.ascending ? 180 : 0
        }
        MouseArea {
            width: browser.nameWidth
            height: parent.height
            onClicked: browser.ascending = !browser.ascending
        }
        Text {
            x: browser.nameWidth + 10
            height: parent.height
            text: qsTr("Date Modified")
            color: browser.secondary
            font {
                family: browser.fontFamily
                pixelSize: 15
            }
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            x: browser.nameWidth + browser.dateWidth + 10
            height: parent.height
            text: qsTr("Size")
            color: browser.secondary
            font {
                family: browser.fontFamily
                pixelSize: 15
            }
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            x: browser.nameWidth + browser.dateWidth + browser.sizeWidth + 10
            height: parent.height
            text: qsTr("Kind")
            color: browser.secondary
            font {
                family: browser.fontFamily
                pixelSize: 15
            }
            verticalAlignment: Text.AlignVCenter
        }
        Repeater {
            model: [browser.nameWidth, browser.nameWidth + browser.dateWidth, browser.nameWidth + browser.dateWidth + browser.sizeWidth]
            Rectangle {
                required property real modelData
                x: modelData
                y: 5
                width: 1
                height: 24
                color: browser.separator
            }
        }
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: browser.separator
        }
    }
    Item {
        id: tableArea
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: browser.headerHeight + 7
            bottom: parent.bottom
        }
        visible: !browser.gridMode
        clip: true
        // Empty rows remain striped as in Finder, and stay aligned during scrolling.
        Repeater {
            model: Math.max(0, Math.ceil(tableArea.height / browser.rowHeight) + 2)
            Rectangle {
                required property int index
                x: 13
                y: (index - 1) * browser.rowHeight - (list.contentY % browser.rowHeight)
                width: tableArea.width - 26
                height: browser.rowHeight
                radius: 6
                color: (Math.floor(list.contentY / browser.rowHeight) + index - 1) % 2 !== 0 ? browser.stripe : "transparent"
            }
        }
        ListView {
            id: list
            objectName: "fileList"
            anchors.fill: parent
            model: browser.visibleFiles
            currentIndex: -1
            clip: true
            activeFocusOnTab: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            onActiveFocusChanged: if (activeFocus && currentIndex < 0 && count > 0)
                currentIndex = 0
            Keys.onUpPressed: {
                currentIndex = Math.max(0, currentIndex - 1);
                browser.selectIndex(currentIndex);
            }
            Keys.onDownPressed: {
                currentIndex = Math.min(count - 1, currentIndex + 1);
                browser.selectIndex(currentIndex);
            }
            ScrollBar.vertical: MacScrollBar {}
            delegate: ItemDelegate {
                id: fileRow
                required property var modelData
                required property int index
                width: list.width
                height: browser.rowHeight
                Accessible.name: fileRow.modelData.name
                onClicked: {
                    list.currentIndex = index;
                    list.forceActiveFocus();
                    browser.selectIndex(index);
                }
                background: Rectangle {
                    x: 13
                    width: parent.width - 26
                    height: parent.height
                    radius: 6
                    color: browser.selectedName === fileRow.modelData.name ? list.activeFocus ? (Theme.dark ? "#245a97" : "#b3d6ff") : (Theme.dark ? "#555558" : "#d8d8db") : fileRow.hovered ? (Theme.dark ? "#16ffffff" : "#08000000") : "transparent"
                }
                contentItem: Item {
                    FinderThumbnail {
                        x: 34
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 14
                        variant: fileRow.modelData.preview
                    }
                    Text {
                        x: 60
                        width: browser.nameWidth - 70
                        height: parent.height
                        text: fileRow.modelData.name
                        color: browser.foreground
                        font {
                            family: browser.fontFamily
                            pixelSize: 18
                        }
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        x: browser.nameWidth + 10
                        width: browser.dateWidth - 18
                        height: parent.height
                        text: fileRow.modelData.date
                        color: browser.secondary
                        font {
                            family: browser.fontFamily
                            pixelSize: 18
                        }
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        x: browser.nameWidth + browser.dateWidth
                        width: browser.sizeWidth - 12
                        height: parent.height
                        text: fileRow.modelData.size
                        color: browser.secondary
                        font {
                            family: browser.fontFamily
                            pixelSize: 18
                        }
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        x: browser.nameWidth + browser.dateWidth + browser.sizeWidth + 10
                        width: browser.kindWidth - 16
                        height: parent.height
                        text: fileRow.modelData.kind
                        color: browser.secondary
                        font {
                            family: browser.fontFamily
                            pixelSize: 18
                        }
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                padding: 0
            }
        }
    }
    GridView {
        id: grid
        objectName: "fileGrid"
        anchors {
            fill: parent
            margins: 16
        }
        visible: browser.gridMode
        model: browser.visibleFiles
        currentIndex: -1
        cellWidth: 156
        cellHeight: 146
        clip: true
        activeFocusOnTab: true
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: true
        onActiveFocusChanged: if (activeFocus && currentIndex < 0 && count > 0)
            currentIndex = 0
        Keys.onRightPressed: {
            currentIndex = Math.min(count - 1, currentIndex + 1);
            browser.selectIndex(currentIndex);
        }
        Keys.onLeftPressed: {
            currentIndex = Math.max(0, currentIndex - 1);
            browser.selectIndex(currentIndex);
        }
        Keys.onUpPressed: {
            currentIndex = Math.max(0, currentIndex - Math.max(1, Math.floor(width / cellWidth)));
            browser.selectIndex(currentIndex);
        }
        Keys.onDownPressed: {
            currentIndex = Math.min(count - 1, currentIndex + Math.max(1, Math.floor(width / cellWidth)));
            browser.selectIndex(currentIndex);
        }
        ScrollBar.vertical: MacScrollBar {}
        delegate: ItemDelegate {
            id: gridRow
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight
            Accessible.name: gridRow.modelData.name
            onClicked: {
                grid.currentIndex = index;
                grid.forceActiveFocus();
                browser.selectIndex(index);
            }
            background: Rectangle {
                anchors {
                    fill: parent
                    margins: 4
                }
                radius: 6
                color: browser.selectedName === gridRow.modelData.name ? (Theme.dark ? "#555558" : "#d8d8db") : "transparent"
            }
            contentItem: Column {
                spacing: 10
                FinderThumbnail {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100
                    height: 76
                    variant: gridRow.modelData.preview
                }
                Text {
                    width: parent.width
                    text: gridRow.modelData.name
                    color: browser.foreground
                    font {
                        family: browser.fontFamily
                        pixelSize: 13
                    }
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: browser.resultCount === 0
        text: qsTr("No items")
        color: browser.secondary
        font {
            family: browser.fontFamily
            pixelSize: 16
        }
    }
}
