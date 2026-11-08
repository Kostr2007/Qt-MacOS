pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtMacOS
import QtMacOS.Demo

MacWindow {
    id: window
    function argument(name, fallback) {
        const args = Qt.application.arguments;
        const index = args.indexOf(name);
        return index >= 0 && index + 1 < args.length ? args[index + 1] : fallback;
    }
    property string currentPage: argument("--page", "collections")
    property string datasetName: argument("--dataset", "studio")
    property string evidenceState: argument("--state", "default")
    property string currentTab: evidenceState === "active" ? "build" : "overview"
    property bool reducedMotion: false
    readonly property var pageNames: [
        {
            key: "boxes",
            title: "Boxes",
            summary: "Related settings form quiet, content-sized groups."
        },
        {
            key: "collections",
            title: "Collections",
            summary: "A responsive collection keeps identity as its data changes."
        },
        {
            key: "columns",
            title: "Column views",
            summary: "Follow a path while keeping its parents in view."
        },
        {
            key: "disclosure",
            title: "Disclosure controls",
            summary: "Reveal additional detail without losing your place."
        },
        {
            key: "labels",
            title: "Labels",
            summary: "A consistent hierarchy makes information easy to scan."
        },
        {
            key: "lists",
            title: "Lists and tables",
            summary: "Two views, one selection, live sorting and resizable columns."
        },
        {
            key: "lockups",
            title: "Lockups · adaptation",
            summary: "Image, title and context share one primary action. Adapted from tvOS."
        },
        {
            key: "outline",
            title: "Outline views",
            summary: "Explore a hierarchy with disclosure and keyboard navigation."
        },
        {
            key: "split",
            title: "Split views",
            summary: "Adjust the space for navigation, content and an inspector."
        },
        {
            key: "tabs",
            title: "Tab views",
            summary: "Change context within a task while retaining each page's state."
        }
    ]
    readonly property var descriptor: pageNames.find(p => p.key === currentPage) || pageNames[1]
    readonly property var selectedRecord: {
        const revision = workspace.revision;
        return workspace.item(workspace.selectedId);
    }
    property alias workspaceModel: workspace
    property alias pageItem: pageLoader.item
    width: Qt.application.arguments.indexOf("--narrow") >= 0 ? 900 : 1280
    height: 880
    minimumWidth: 800
    minimumHeight: 650
    surfaceColor: Theme.content
    title: descriptor.title + " — Qt-MacOS Workspace"
    WorkspaceModel {
        id: workspace
        dataset: window.datasetName
        filter: filter.text
    }
    Component.onCompleted: {
        Theme.dark = Qt.application.arguments.indexOf("--dark") >= 0;
        if (evidenceState === "active")
            Qt.callLater(() => {
                workspace.selectedId = workspace.entryIdAt(1);
                if (pageLoader.item)
                    pageLoader.item.forceActiveFocus();
            });
    }
    function entryAt(index) {
        const revision = workspace.revision;
        return workspace.item(workspace.entryIdAt(index));
    }
    function requestSelection(id) {
        workspace.selectedId = id;
    }

    Rectangle {
        width: 208
        height: parent.height - 2
        x: 1
        y: 1
        color: Theme.sidebar
        radius: window.corner - 1
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 12
            color: Theme.sidebar
        }
        WindowButtons {
            x: 24
            y: 24
            dark: Theme.dark
            windowActive: window.active || window.presentation
            onCloseRequested: window.close()
            onMinimizeRequested: window.showMinimized()
            onZoomRequested: window.zoom()
        }
        MacLabel {
            x: 20
            y: 70
            text: "Workspace"
            role: MacLabel.Heading
        }
        MacLabel {
            x: 20
            y: 95
            text: "Layout & organization"
            role: MacLabel.Caption
        }
        ListView {
            id: navigation
            x: 10
            y: 132
            width: parent.width - 20
            height: parent.height - y - 60
            model: window.pageNames
            clip: true
            spacing: 3
            delegate: ItemDelegate {
                id: navItem
                required property var modelData
                width: navigation.width
                height: 40
                text: modelData.title
                highlighted: window.currentPage === modelData.key
                onClicked: window.currentPage = modelData.key
                font.pixelSize: 13
                palette.text: Theme.text
                palette.highlightedText: Theme.text
                background: Rectangle {
                    radius: 6
                    color: navItem.highlighted ? Theme.selection : navItem.hovered ? Theme.hover : "transparent"
                }
            }
        }
        MacLabel {
            x: 20
            y: parent.height - 42
            text: "Qt-MacOS / Design system"
            role: MacLabel.Caption
        }
    }
    MouseArea {
        x: 210; y: 1
        width: parent.width - x - 1; height: 78
        onPressed: window.startSystemMove()
        onDoubleClicked: window.zoom()
    }
    Item {
        id: content
        x: 232
        y: 22
        width: parent.width - x - 24
        height: parent.height - 44
        Column {
            id: heading
            width: parent.width
            spacing: 5
            MacLabel {
                text: window.descriptor.title
                role: MacLabel.Title
                width: parent.width
            }
            MacLabel {
                text: window.descriptor.summary
                role: MacLabel.Secondary
                width: parent.width
            }
        }
        RowLayout {
            id: commands
            y: heading.height + 18
            width: parent.width
            spacing: 10
            SearchField {
                id: filter
                objectName: "workspaceFilter"
                placeholderText: qsTr("Filter workspace")
                Layout.fillWidth: true
            }
            MacPopupButton {
                objectName: "workspaceDataset"
                implicitWidth: 150
                model: ["Studio", "Library"]
                currentIndex: window.datasetName === "studio" ? 0 : 1
                onActivated: window.datasetName = currentIndex === 0 ? "studio" : "library"
                Accessible.name: qsTr("Workspace dataset")
            }
            MacPushButton {
                objectName: "addWorkspaceItem"
                text: qsTr("Add item")
                font.pixelSize: 13
                onClicked: workspace.appendItem("", "Untitled resource")
            }
            MacPushButton {
                objectName: "layoutTheme"
                text: Theme.dark ? qsTr("Light") : qsTr("Dark")
                font.pixelSize: 13
                onClicked: Theme.dark = !Theme.dark
            }
        }
        Loader {
            id: pageLoader
            y: commands.y + commands.height + 20
            width: parent.width
            height: parent.height - y - 32
            sourceComponent: window.currentPage === "boxes" ? boxesPage : window.currentPage === "columns" ? columnsPage : window.currentPage === "disclosure" ? disclosurePage : window.currentPage === "labels" ? labelsPage : window.currentPage === "lists" ? listsPage : window.currentPage === "lockups" ? lockupsPage : window.currentPage === "outline" ? outlinePage : window.currentPage === "split" ? splitPage : window.currentPage === "tabs" ? tabsPage : collectionsPage
        }
        MacLabel {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            role: MacLabel.Caption
            text: workspace.entryCount + " resources · " + (workspace.selectedId ? window.selectedRecord.title || workspace.selectedId : "Nothing selected")
        }
    }
    Component {
        id: boxesPage
        ScrollView {
            contentWidth: availableWidth
            Column {
                width: parent.width
                spacing: 22
                MacBox {
                    width: parent.width
                    title: qsTr("Project details")
                    MacLabel {
                        text: window.datasetName === "studio" ? "Orbital landscapes" : "Путешествия: фотографии, документы и звуки"
                        role: MacLabel.Heading
                        width: parent.width
                    }
                    MacLabel {
                        text: qsTr("Related information stays together. Groups grow with their content, while the window keeps its own hierarchy.")
                        width: parent.width
                    }
                    MacTextField {
                        width: parent.width
                        text: window.datasetName === "studio" ? "Orbit / Summer edition" : "Архив материалов — версия для совместной работы"
                        Accessible.name: qsTr("Project name")
                    }
                    MacLabel {
                        visible: window.evidenceState === "active"
                        text: qsTr("Changes are saved in the demo model for this session.")
                        role: MacLabel.Secondary
                        width: parent.width
                    }
                }
                MacBox {
                    width: parent.width
                    title: qsTr("Build preferences")
                    MacCheckBox {
                        text: qsTr("Include preview images")
                        checked: true
                    }
                    MacCheckBox {
                        text: qsTr("Keep a copy of source assets")
                        checked: window.evidenceState === "active"
                    }
                    MacLabel {
                        role: MacLabel.Caption
                        text: qsTr("A quiet box groups a small set of related decisions.")
                        width: parent.width
                    }
                }
            }
        }
    }
    Component {
        id: collectionsPage
        MacCollectionView {
            objectName: "workspaceCollection"
            model: workspace.entries
            selectedId: workspace.selectedId
            onSelectionRequested: id => window.requestSelection(id)
            onActivated: preview.open()
        }
    }
    Component {
        id: columnsPage
        MacColumnBrowser {
            objectName: "workspaceColumns"
            source: workspace
            selectedId: workspace.selectedId
            onSelectionRequested: id => window.requestSelection(id)
        }
    }
    Component {
        id: disclosurePage
        ScrollView {
            contentWidth: availableWidth
            Column {
                width: parent.width
                spacing: 20
                MacLabel {
                    role: MacLabel.Secondary
                    text: qsTr("Essential choices remain visible. Additional detail opens in place.")
                    width: parent.width
                }
                MacDisclosureGroup {
                    id: exportGroup
                    objectName: "exportDisclosure"
                    title: qsTr("Export settings")
                    width: parent.width
                    expanded: window.evidenceState === "active"
                    reducedMotion: window.reducedMotion
                    MacBox {
                        width: parent.width
                        MacLabel {
                            text: qsTr("Choose how to package this workspace.")
                            width: parent.width
                        }
                        MacPopupButton {
                            width: Math.min(300, parent.width)
                            model: ["Portable archive", "Directory", "Source package"]
                            Accessible.name: qsTr("Export format")
                        }
                        MacCheckBox {
                            text: qsTr("Include metadata")
                            checked: true
                        }
                    }
                }
                MacDisclosureGroup {
                    title: qsTr("Advanced options")
                    width: parent.width
                    reducedMotion: window.reducedMotion
                    MacLabel {
                        text: qsTr("These choices are available when needed without competing with the primary task.")
                        width: parent.width
                    }
                    MacDisclosureGroup {
                        title: qsTr("Diagnostics")
                        width: parent.width
                        MacCheckBox {
                            text: qsTr("Write a detailed report")
                        }
                    }
                }
            }
        }
    }
    Component {
        id: labelsPage
        ScrollView {
            contentWidth: availableWidth
            Column {
                width: parent.width
                spacing: 18
                MacLabel {
                    role: MacLabel.Title
                    text: window.datasetName === "studio" ? "A place for your ideas" : "Пространство для ваших проектов"
                    width: parent.width
                }
                MacLabel {
                    role: MacLabel.Heading
                    text: qsTr("Workspace overview")
                    width: parent.width
                }
                MacLabel {
                    role: MacLabel.Body
                    text: qsTr("Primary text explains the task in plain language. It wraps with the available space and keeps a consistent baseline and rhythm.")
                    width: parent.width
                }
                MacLabel {
                    role: MacLabel.Secondary
                    text: qsTr("Secondary text provides context without becoming another heading.")
                    width: parent.width
                }
                MacLabel {
                    role: MacLabel.Caption
                    text: qsTr("Updated today · Shared with your team")
                    width: parent.width
                }
                MacBox {
                    width: parent.width
                    title: qsTr("Long content")
                    MacLabel {
                        width: parent.width
                        text: "Большое название документа и подробное описание должны оставаться читаемыми в узком окне. Макет переносит строки, сохраняя порядок и смысл информации."
                    }
                    MacLabel {
                        width: parent.width
                        role: MacLabel.Secondary
                        enabled: window.evidenceState !== "active"
                        text: qsTr("Supporting information uses the same semantic role across views.")
                    }
                }
            }
        }
    }
    Component {
        id: listsPage
        MacSplitView {
            objectName: "workspaceDataSplit"
            MacListView {
                objectName: "workspaceList"
                SplitView.preferredWidth: 260
                SplitView.minimumWidth: 160
                model: workspace.entries
                selectedId: workspace.selectedId
                onSelectionRequested: id => window.requestSelection(id)
            }
            MacTableView {
                objectName: "workspaceTable"
                SplitView.fillWidth: true
                SplitView.minimumWidth: 260
                model: workspace.entries
                selectedId: workspace.selectedId
                onSelectionRequested: id => window.requestSelection(id)
                onSortRequested: (column, ascending) => workspace.sortEntries(column, ascending)
            }
        }
    }
    Component {
        id: lockupsPage
        ScrollView {
            contentWidth: availableWidth
            Column {
                width: parent.width
                spacing: 18
                MacLabel {
                    role: MacLabel.Secondary
                    width: parent.width
                    text: qsTr("Content cards are a cross-platform adaptation of the tvOS lockup pattern, not a native macOS control.")
                }
                Flow {
                    width: parent.width
                    spacing: 16
                    Repeater {
                        model: Math.min(4, workspace.entryCount)
                        MacLockup {
                            required property int index
                            readonly property var record: window.entryAt(index)
                            width: Math.max(160, (parent.width - 16) / 2)
                            height: 190
                            itemId: record.itemId || ""
                            title: record.title || ""
                            subtitle: record.subtitle || ""
                            kind: record.kind || "image"
                            tint: record.tint || "#52b9ed"
                            selected: workspace.selectedId === itemId
                            onActivated: window.requestSelection(itemId)
                        }
                    }
                }
            }
        }
    }
    Component {
        id: outlinePage
        MacSplitView {
            MacOutlineView {
                objectName: "workspaceOutline"
                SplitView.fillWidth: true
                SplitView.minimumWidth: 220
                model: workspace
                selectedId: workspace.selectedId
                onSelectionRequested: id => window.requestSelection(id)
            }
            MacBox {
                SplitView.preferredWidth: 240
                SplitView.minimumWidth: 180
                title: qsTr("Inspector")
                MacLabel {
                    text: window.selectedRecord.title || qsTr("Select an item")
                    role: MacLabel.Heading
                    width: parent.width
                }
                MacLabel {
                    text: window.selectedRecord.subtitle || qsTr("Hierarchy and selection stay in sync with other views.")
                    width: parent.width
                }
                MacPushButton {
                    enabled: workspace.selectedId.length > 0
                    text: qsTr("Rename…")
                    onClicked: rename.open()
                }
            }
        }
    }
    Component {
        id: splitPage
        MacSplitView {
            id: splitView
            objectName: "workspaceSplit"
            MacListView {
                SplitView.preferredWidth: 210
                SplitView.minimumWidth: 140
                model: workspace.entries
                selectedId: workspace.selectedId
                onSelectionRequested: id => window.requestSelection(id)
            }
            MacBox {
                SplitView.fillWidth: true
                SplitView.minimumWidth: 220
                title: qsTr("Content")
                MacLabel {
                    role: MacLabel.Heading
                    text: window.selectedRecord.title || qsTr("Your workspace")
                    width: parent.width
                }
                MacLabel {
                    text: qsTr("Drag the separators to adjust the space for your task. The inspector can be hidden and restored.")
                    width: parent.width
                }
                MacPushButton {
                    text: qsTr("Restore inspector")
                    onClicked: splitView.restorePane(2)
                }
            }
            MacBox {
                SplitView.preferredWidth: 220
                SplitView.minimumWidth: 160
                title: qsTr("Inspector")
                MacLabel {
                    text: qsTr("Details for the selected resource")
                    width: parent.width
                }
                MacDisclosureGroup {
                    objectName: "splitMetadata"
                    title: qsTr("Metadata")
                    width: parent.width
                    expanded: true
                    MacLabel {
                        text: window.selectedRecord.kind || qsTr("No selection")
                        width: parent.width
                    }
                }
            }
            Component.onCompleted: if (window.evidenceState === "active")
                Qt.callLater(() => splitView.setPaneCollapsed(2, true))
        }
    }
    Component {
        id: tabsPage
        MacTabView {
            objectName: "workspaceTabs"
            tabs: [
                {
                    key: "overview",
                    title: "Overview"
                },
                {
                    key: "build",
                    title: "Build"
                },
                {
                    key: "history",
                    title: "Resources"
                }
            ]
            currentKey: window.currentTab
            onCurrentKeyRequested: key => window.currentTab = key
            pageDelegate: Component {
                Item {
                    id: tabPage
                    property string pageKey
                    property string draft: ""
                    Column {
                        anchors {
                            fill: parent
                            margins: 18
                        }
                        spacing: 16
                        MacLabel {
                            role: MacLabel.Heading
                            text: tabPage.pageKey === "overview" ? "Project overview" : tabPage.pageKey === "build" ? "Build configuration" : "Workspace resources"
                            width: parent.width
                        }
                        MacLabel {
                            width: parent.width
                            text: qsTr("Each page retains its state while you switch between related tasks.")
                        }
                        MacTextField {
                            objectName: "tabDraft-" + tabPage.pageKey
                            width: parent.width
                            placeholderText: qsTr("Write a note for this page")
                            text: tabPage.draft
                            onTextEdited: tabPage.draft = text
                            Accessible.name: qsTr("Page notes")
                        }
                        MacCheckBox {
                            text: qsTr("Include previews")
                            checked: tabPage.pageKey === "build"
                        }
                        MacLabel {
                            role: MacLabel.Caption
                            text: workspace.entryCount + qsTr(" resources in this workspace")
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
    MacDialog {
        id: preview
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 420
        title: window.selectedRecord.title || "Resource"
        standardButtons: Dialog.Close
        contentItem: MacLabel {
            text: window.selectedRecord.subtitle || qsTr("This item belongs to the shared workspace model.")
            width: parent.width
        }
    }
    MacDialog {
        id: rename
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 420
        title: qsTr("Rename resource")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: {
            newName.text = window.selectedRecord.title || "";
            newName.forceActiveFocus();
            newName.selectAll();
        }
        contentItem: MacTextField {
            id: newName
            Accessible.name: qsTr("Resource name")
        }
        onAccepted: workspace.renameItem(workspace.selectedId, newName.text)
    }
}
