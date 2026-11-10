pragma ComponentBehavior: Bound
import QtQuick
import QtMacOS
import QtQuick.Controls.Basic as Basic

Rectangle {
    id: sidebar
    property bool dark: false
    property bool windowActive: true
    property string currentKey: "Mouse"
    property string fontFamily: "Inter Variable"
    property alias searchText: search.text
    property Basic.ItemDelegate hoveredRow: null
    property real hoverTargetY: 0
    property real hoverTargetHeight: 44
    property bool hoverMotionEnabled: false
    property real hoverVelocity: 0
    property real hoverFrequency: 22
    function trackHover(item) {
        if (!item || !item.hovered) return;
        if (!hoveredRow || hoverIndicator.opacity < 0.01) {
            hoverMotionEnabled = false;
            Qt.callLater(function() { sidebar.hoverMotionEnabled = true; });
        }
        hoveredRow = item;
        hoverTargetY = item.parent.y + item.y;
        hoverTargetHeight = item.height;
        if (!hoverMotionEnabled || Theme.reducedMotion) {
            hoverIndicator.y = hoverTargetY;
            hoverVelocity = 0;
        }
    }
    FrameAnimation {
        running: sidebar.hoverMotionEnabled && !Theme.reducedMotion
            && (Math.abs(hoverIndicator.y - sidebar.hoverTargetY) > 0.01 || Math.abs(sidebar.hoverVelocity) > 0.1)
        onTriggered: {
            // Same exact critically damped integration as slider feedback.
            // Retargeting preserves velocity instead of restarting an easing curve.
            const dt = Math.max(0.001, Math.min(0.05, frameTime || 1 / 60));
            const frequency = Math.max(4, Math.min(80, sidebar.hoverFrequency));
            const delta = hoverIndicator.y - sidebar.hoverTargetY;
            const c = sidebar.hoverVelocity + frequency * delta;
            const decay = Math.exp(-frequency * dt);
            hoverIndicator.y = sidebar.hoverTargetY + (delta + c * dt) * decay;
            sidebar.hoverVelocity = (sidebar.hoverVelocity - frequency * c * dt) * decay;
            if (Math.abs(hoverIndicator.y - sidebar.hoverTargetY) <= 0.01 && Math.abs(sidebar.hoverVelocity) <= 0.1) {
                hoverIndicator.y = sidebar.hoverTargetY;
                sidebar.hoverVelocity = 0;
            }
        }
    }
    Connections {
        target: Theme
        function onReducedMotionChanged() {
            if (Theme.reducedMotion) {
                hoverIndicator.y = sidebar.hoverTargetY;
                sidebar.hoverVelocity = 0;
            }
        }
    }
    signal navigate(string key)
    implicitWidth: 300
    radius: 28
    color: dark ? "#30383d" : "#eef8fa"
    gradient: Gradient {
        GradientStop {
            position: 0
            color: sidebar.dark ? "#30383d" : "#eaf8fe"
        }
        GradientStop {
            position: 0.5
            color: sidebar.dark ? "#30363b" : "#f5fbfd"
        }
        GradientStop {
            position: 1
            color: sidebar.dark ? "#303832" : "#eff9f4"
        }
    }
    readonly property color foreground: dark ? "#f0f0f2" : "#242527"
    property var entries: []
    readonly property var visibleEntries: {
        const query = search.text.trim().toLocaleLowerCase();
        return entries.filter(item => !query || item.key.toLocaleLowerCase().includes(query));
    }
    function focusSearch() {
        search.forceActiveFocus();
        search.selectAll();
    }
    function focusResult(index) {
        if (!visibleEntries.length) return;
        const target = Math.max(0, Math.min(visibleEntries.length - 1, index));
        navigation.currentIndex = target;
        navigation.positionViewAtIndex(target, ListView.Contain);
        navigation.forceLayout();
        const item = navigation.itemAtIndex(target);
        if (item) item.forceActiveFocus(Qt.TabFocusReason);
    }
    function leaveSearch() {
        if (search.text.length) search.clear();
        else focusResult(Math.max(0, visibleEntries.findIndex(item => item.key === currentKey)));
    }
    function revealCurrent() {
        if (!search.text.length) {
            const index = visibleEntries.findIndex(item => item.key === currentKey);
            if (index >= 0) {
                navigation.currentIndex = index;
                navigation.positionViewAtIndex(index, ListView.Contain);
            }
        }
    }
    onCurrentKeyChanged: Qt.callLater(revealCurrent)
    Component.onCompleted: Qt.callLater(revealCurrent)

    Basic.TextField {
        id: search
        objectName: "settingsSearch"
        x: 22
        y: 88
        width: parent.width - 42
        height: 38
        leftPadding: 36
        rightPadding: clearSearch.visible ? 34 : 12
        selectByMouse: true
        font {
            family: sidebar.fontFamily
            pixelSize: 16
        }
        color: sidebar.foreground
        placeholderText: qsTr("Search")
        placeholderTextColor: sidebar.dark ? "#aeb5ba" : "#849297"
        Accessible.name: qsTr("Search settings")
        Keys.onEscapePressed: sidebar.leaveSearch()
        Keys.onDownPressed: sidebar.focusResult(0)
        onAccepted: sidebar.focusResult(0)
        onTextChanged: {
            navigation.contentY = 0;
            if (!text.length)
                Qt.callLater(sidebar.revealCurrent);
        }
        background: Rectangle {
            radius: 19
            color: sidebar.dark ? "#424c52" : "#dfebef"
            border.width: search.activeFocus ? 2 : 0
            border.color: "#55a0ef"
        }
        SettingsIcon {
            x: 11
            anchors.verticalCenter: parent.verticalCenter
            width: 19
            height: 19
            name: "search"
            color: sidebar.dark ? "#aeb5ba" : "#849297"
        }
        Basic.ToolButton {
            id: clearSearch
            objectName: "settingsClearSearch"
            visible: search.text.length > 0
            x: parent.width - width - 4
            anchors.verticalCenter: parent.verticalCenter
            width: 28; height: 28
            hoverEnabled: true
            Accessible.name: qsTr("Clear search")
            onClicked: { search.clear(); search.forceActiveFocus(Qt.OtherFocusReason); }
            background: Rectangle {
                anchors.centerIn: parent
                width: 16; height: 16; radius: 8
                color: sidebar.foreground
                opacity: clearSearch.down ? 0.65 : clearSearch.hovered ? 0.5 : 0.35
                Behavior on opacity { NumberAnimation { duration: Theme.colorDuration } }
            }
            contentItem: Item {
                Rectangle { anchors.centerIn: parent; width: 8; height: 1.4; radius: 0.7; rotation: 45; color: sidebar.dark ? "#424c52" : "#dfebef"; antialiasing: true }
                Rectangle { anchors.centerIn: parent; width: 8; height: 1.4; radius: 0.7; rotation: -45; color: sidebar.dark ? "#424c52" : "#dfebef"; antialiasing: true }
                Rectangle { anchors.fill: parent; radius: 14; color: "transparent"; border.color: Theme.accent; border.width: clearSearch.visualFocus ? 2 : 0 }
            }
        }
    }
    ListView {
        id: navigation
        objectName: "settingsNavigation"
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: 20
            rightMargin: 15
            topMargin: 132
            bottomMargin: 14
        }
        model: sidebar.visibleEntries
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        onHeightChanged: Qt.callLater(sidebar.revealCurrent)
        Basic.ScrollBar.vertical: MacScrollBar {
            objectName: "settingsScrollBar"
        }
        Rectangle {
            id: hoverIndicator
            objectName: "settingsHoverIndicator"
            parent: navigation.contentItem
            z: -1
            x: 0
            y: 0
            width: navigation.width - 12
            height: sidebar.hoverTargetHeight
            radius: 10
            antialiasing: true
            color: sidebar.dark ? "#454f56" : "#e0ebee"
            opacity: sidebar.windowActive && sidebar.hoveredRow && sidebar.hoveredRow.hovered && !sidebar.hoveredRow.highlighted ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.sidebarHoverDuration; easing.type: Easing.InOutCubic }
            }
        }
        delegate: FocusScope {
            id: row
            required property var modelData
            required property int index
            width: navigation.width - 12
            height: 44 + (modelData.gap && !search.text.length ? 20 : 0)
            onYChanged: if (sidebar.hoveredRow === button) sidebar.trackHover(button)
            Basic.ItemDelegate {
                id: button
                objectName: "settingsItem_" + row.modelData.key
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 44
                padding: 8
                hoverEnabled: true
                focus: true
                focusPolicy: row.index === navigation.currentIndex ? Qt.StrongFocus : Qt.ClickFocus
                Accessible.name: row.modelData.key
                highlighted: sidebar.currentKey === row.modelData.key
                onHoveredChanged: if (hovered) sidebar.trackHover(button)
                onClicked: sidebar.navigate(row.modelData.key)
                Keys.onUpPressed: sidebar.focusResult(row.index - 1)
                Keys.onDownPressed: sidebar.focusResult(row.index + 1)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                        sidebar.focusResult(event.key === Qt.Key_Home ? 0 : sidebar.visibleEntries.length - 1);
                        event.accepted = true;
                    }
                }
                Keys.onReturnPressed: sidebar.navigate(row.modelData.key)
                Keys.onEnterPressed: sidebar.navigate(row.modelData.key)
                background: MacSelectionBackground {
                    id: rowSelection
                    radius: 10
                    selected: button.highlighted
                    animateSelection: true
                    // Lists use a row highlight for keyboard focus. Keep the
                    // selected category separate while browsing other results.
                    hovered: button.visualFocus && sidebar.windowActive && !button.highlighted
                    focused: false
                    selectionColor: sidebar.windowActive ? "#0067d8" : Theme.inactiveSelection
                    hoverColor: sidebar.dark ? "#454f56" : "#e0ebee"
                }
                contentItem: Item {
                    Rectangle {
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 6
                        antialiasing: true
                        color: row.modelData.tint
                        border.width: 0.5
                        border.color: "#12000000"
                        SettingsIcon {
                            anchors.fill: parent
                            name: row.modelData.icon
                        }
                    }
                    Text {
                        x: 38
                        width: parent.width - 40
                        height: parent.height
                        text: row.modelData.key
                        color: sidebar.windowActive && rowSelection.selectionProgress > 0.65 ? "white" : sidebar.foreground
                        font {
                            family: sidebar.fontFamily
                            pixelSize: 17
                        }
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
    Text {
        objectName: "settingsNoResults"
        visible: sidebar.visibleEntries.length === 0 && search.text.trim().length > 0
        x: 24; y: 155
        width: parent.width - 48
        text: qsTr("No results")
        color: sidebar.foreground
        horizontalAlignment: Text.AlignHCenter
        font.family: sidebar.fontFamily
        font.pixelSize: 15
        Accessible.role: Accessible.StaticText
        Accessible.name: text
    }
}
