pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtMacOS

MacWindow {
    id: window
    title: section + " — Qt-MacOS Finder"
    surfaceObjectName: "finderFrame"
    property string section: "Documents"
    property bool searchOpen: false
    property var history: ["Documents"]
    property int historyIndex: 0
    readonly property color foreground: Theme.dark ? "#ededee" : "#28282a"
    readonly property color glyphColor: Theme.dark ? "#b9b9bc" : "#68686c"
    function navigate(destination) {
        if (destination === section)
            return;
        history = history.slice(0, historyIndex + 1).concat([destination]);
        historyIndex = history.length - 1;
        section = destination;
    }
    function revealSearch() {
        searchOpen = true;
        search.forceActiveFocus();
    }
    Component.onCompleted: {
        Theme.dark = Qt.application.arguments.indexOf("--light") < 0;
        Theme.reducedMotion = Qt.application.arguments.indexOf("--reduce-motion") >= 0;
        browser.gridMode = Qt.application.arguments.indexOf("--grid") >= 0;
    }
    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: window.revealSearch()
    }
    Shortcut {
        sequences: [StandardKey.Cancel]
        onActivated: {
            search.clear();
            window.searchOpen = false;
            browser.forceActiveFocus();
        }
    }
    Shortcut {
        sequence: "Ctrl+Shift+L"
        onActivated: Theme.dark = !Theme.dark
    }

    FinderSidebar {
        id: sidebar
        objectName: "finderSidebar"
        width: 170
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: 1
        }
        radius: Math.max(0, window.corner - 1)
        dark: Theme.dark
        windowActive: window.active || window.presentation
        selectedTitle: window.section
        onNavigate: title => window.navigate(title)
        onCloseRequested: window.close()
        onMinimizeRequested: window.showMinimized()
        onZoomRequested: window.zoom()
    }
    Rectangle {
        x: sidebar.width + 1
        y: 1
        width: 1
        height: parent.height - 2
        color: Theme.dark ? "#111113" : "#b6b6b9"
    }
    Rectangle {
        id: toolbar
        x: sidebar.width + 2
        y: 1
        width: parent.width - x - 1
        height: 66
        radius: Math.max(0, window.corner - 1)
        color: Theme.dark ? "#39393b" : "#f0f0f2"
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: 12
            color: toolbar.color
        }
        Rectangle {
            anchors {
                left: parent.left
                bottom: parent.bottom
                right: parent.right
            }
            height: 12
            color: toolbar.color
        }
        MouseArea {
            anchors.fill: parent
            onPressed: window.startSystemMove()
            onDoubleClicked: window.zoom()
        }
        RowLayout {
            anchors {
                fill: parent
                leftMargin: 18
                rightMargin: 16
            }
            spacing: 14
            FinderToolButton {
                objectName: "backButton"
                symbol: "back"
                text: qsTr("Back")
                glyphColor: window.glyphColor
                enabled: window.historyIndex > 0
                onClicked: {
                    --window.historyIndex;
                    window.section = window.history[window.historyIndex];
                }
            }
            FinderToolButton {
                objectName: "forwardButton"
                symbol: "forward"
                text: qsTr("Forward")
                glyphColor: window.glyphColor
                enabled: window.historyIndex < window.history.length - 1
                onClicked: {
                    ++window.historyIndex;
                    window.section = window.history[window.historyIndex];
                }
            }
            Label {
                text: window.section
                color: window.foreground
                font {
                    pixelSize: 20
                    weight: Font.DemiBold
                }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            RowLayout {
                spacing: 0
                FinderToolButton {
                    objectName: "listMode"
                    symbol: "list"
                    text: qsTr("List view")
                    glyphColor: window.glyphColor
                    onClicked: browser.gridMode = false
                }
                FinderToolButton {
                    objectName: "sortButton"
                    symbol: "sort"
                    text: qsTr("Reverse sort order")
                    implicitWidth: 20
                    padding: 3
                    glyphColor: window.glyphColor
                    onClicked: browser.ascending = !browser.ascending
                }
            }
            Item {
                implicitWidth: 36
            }
            RowLayout {
                spacing: 0
                FinderToolButton {
                    objectName: "gridMode"
                    symbol: "grid"
                    text: qsTr("Icon view")
                    glyphColor: window.glyphColor
                    onClicked: browser.gridMode = true
                }
                FinderToolButton {
                    symbol: "chevron"
                    text: qsTr("View options")
                    implicitWidth: 20
                    padding: 3
                    glyphColor: window.glyphColor
                    onClicked: viewMenu.popup()
                }
            }
            FinderToolButton {
                symbol: "share"
                text: qsTr("Share (not available in sample catalogue)")
                glyphColor: window.glyphColor
                enabled: false
            }
            FinderToolButton {
                symbol: "tag"
                text: qsTr("Tags (not available in sample catalogue)")
                glyphColor: window.glyphColor
                enabled: false
            }
            RowLayout {
                spacing: 0
                FinderToolButton {
                    objectName: "moreButton"
                    symbol: "more"
                    text: qsTr("More actions")
                    glyphColor: window.glyphColor
                    onClicked: viewMenu.popup()
                }
                FinderToolButton {
                    symbol: "chevron"
                    text: qsTr("More options")
                    implicitWidth: 20
                    padding: 3
                    glyphColor: window.glyphColor
                    onClicked: viewMenu.popup()
                }
            }
            FinderToolButton {
                objectName: "searchButton"
                symbol: "search"
                text: qsTr("Search")
                glyphColor: window.glyphColor
                visible: !window.searchOpen
                Layout.leftMargin: 34
                onClicked: window.revealSearch()
            }
            SearchField {
                id: search
                objectName: "search"
                visible: window.searchOpen
                Layout.preferredWidth: 160
                font.family: window.font.family
            }
        }
        MacMenu {
            id: viewMenu
            objectName: "viewMenu"
            x: toolbar.width - width - 24
            y: 54
            palette.window: Theme.dark ? "#424244" : "#f5f5f5"
            palette.text: window.foreground
            MenuItem {
                text: qsTr("as List")
                onTriggered: browser.gridMode = false
            }
            MenuItem {
                text: qsTr("as Icons")
                onTriggered: browser.gridMode = true
            }
            MenuSeparator {}
            MenuItem {
                objectName: "reduceMotionToggle"
                text: qsTr("Reduce Motion")
                checkable: true
                checked: Theme.reducedMotion
                onTriggered: Theme.reducedMotion = !Theme.reducedMotion
            }
            MenuItem {
                objectName: "themeToggle"
                text: Theme.dark ? qsTr("Use Light Appearance") : qsTr("Use Dark Appearance")
                onTriggered: Theme.dark = !Theme.dark
            }
        }
    }
    FileBrowser {
        id: browser
        objectName: "browser"
        x: sidebar.width + 2
        y: toolbar.height + 1
        width: parent.width - x - 1
        height: parent.height - y - 1
        query: search.text
        category: window.section
        transparentBackground: true
        fontFamily: window.font.family
    }
}
