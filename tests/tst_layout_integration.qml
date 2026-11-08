import QtQuick
import QtQuick.Controls.Basic
import QtTest
import QtMacOS
import QtMacOS.Demo
import "../demo" as Demo

TestCase {
    name: "LayoutIntegration"
    when: windowShown
    Component { id: workspaceWindow; Demo.LayoutMain {} }
    property var app
    function init() {
        failOnWarning(/.*/)
        app = createTemporaryObject(workspaceWindow, null)
        verify(app !== null)
        if (typeof layoutStoryDirectory !== "undefined" && layoutStoryDirectory.length)
            app.presentation = true
        verify(waitForRendering(app.contentItem))
    }
    function captureStep(name) {
        if (typeof layoutStoryDirectory === "undefined" || !layoutStoryDirectory.length) return
        wait(40)
        const image = grabImage(app.contentItem)
        verify(image.width > 0 && image.height > 0)
        image.save(layoutStoryDirectory + "/" + name + ".png")
    }
    function accessibleChild(item, name) {
        if (item.Accessible.name === name) return item
        for (let child of item.children) {
            const found = accessibleChild(child, name)
            if (found) return found
        }
        return null
    }
    function source() { return app.workspaceModel }
    function page(key, objectName) {
        app.currentPage = key
        const result = objectName ? findChild(app, objectName) : app.pageItem
        verify(result !== null)
        return result
    }
    function test_oneSelectionAcrossViewsSortAndRename() {
        const model = source()
        const id = model.entries.itemIdAt(2)
        const collection = findChild(app, "workspaceCollection")
        const grid = findChild(collection,"macCollectionGrid")
        tryVerify(() => grid.itemAtIndex(2) !== null)
        mouseClick(grid.itemAtIndex(2))
        compare(model.selectedId,id)
        compare(collection.selectedId, id)
        captureStep("01-collection-selection")
        page("lists")
        const list = findChild(app,"workspaceList")
        const table = findChild(app,"workspaceTable")
        const tableContent = findChild(table,"macTableContent")
        tryVerify(() => tableContent.itemAtCell(Qt.point(0,0)) !== null)
        compare(tableContent.itemAtCell(Qt.point(0,0)).Accessible.name,
                model.item(model.entries.itemIdAt(0)).title)
        compare(list.selectedId, id); compare(table.selectedId, id)
        captureStep("02-shared-selection")
        mouseClick(findChild(table,"macTableHeading0"), 40, 15)
        mouseClick(findChild(table,"macTableHeading0"), 40, 15)
        compare(model.selectedId, id)
        captureStep("03-sorted-with-selection")
        verify(model.renameItem(id,"Renamed resource"))
        compare(model.selectedId,id)
        compare(model.item(id).title,"Renamed resource")
        table.forceActiveFocus(); keyClick(Qt.Key_End)
        compare(model.selectedId,model.entries.itemIdAt(model.entryCount-1))
    }
    function test_addRemoveAndFilterAffectAllViews() {
        const model = source()
        const before = model.entryCount
        mouseClick(findChild(app,"addWorkspaceItem"))
        tryCompare(model,"entryCount",before+1)
        compare(findChild(app,"workspaceCollection").itemCount,before+1)
        const id = model.entries.itemIdAt(1)
        model.selectedId=id
        verify(model.removeItem(id))
        compare(model.selectedId,"")
        compare(model.entryCount,before)
        const field = findChild(app,"workspaceFilter")
        field.text = "UNMATCHABLE-ITEM"
        tryCompare(model,"entryCount",0)
        compare(findChild(app,"workspaceCollection").itemCount,0)
        field.text = ""
        tryCompare(model,"entryCount",before)
    }
    function test_alternateDataAndResponsiveCollection() {
        const model = source()
        const first = model.entries.itemIdAt(0)
        app.datasetName="library"
        tryCompare(model,"dataset","library")
        verify(model.entries.itemIdAt(0)!==first)
        const collection=findChild(app,"workspaceCollection")
        const columns=collection.columnCount
        app.width=900
        tryVerify(() => collection.columnCount < columns)
        compare(collection.itemCount,model.entryCount)
    }
    function test_columnHierarchyKeyboard() {
        const model=source()
        const column=page("columns","workspaceColumns")
        model.selectedId="project-orbit"
        tryCompare(column,"selectedId","project-orbit")
        tryVerify(() => column.columns.length === 2)
        compare(column.selectedPath.length,1)
        column.forceActiveFocus(); keyClick(Qt.Key_Right)
        compare(model.selectedId,model.childrenFor("project-orbit")[0].itemId)
        keyClick(Qt.Key_Right)
        compare(column.selectedPath.length,3)
        captureStep("10-column-keyboard-path")
        keyClick(Qt.Key_Left)
        compare(column.selectedPath.length,2)
    }
    function test_outlineShowsAncestorsAndCollapseReturnsSelection() {
        const model=source()
        const outline=page("outline","workspaceOutline")
        const leaf=model.childrenFor("textures")[0].itemId
        model.selectedId=leaf
        tryVerify(() => outline.view.rows > 3)
        const ancestorRow=outline.view.cellAtIndex(model.indexForId("assets")).y
        verify(ancestorRow >= 0)
        outline.collapseRow(ancestorRow)
        tryCompare(model,"selectedId","assets")
        tryVerify(() => !outline.view.isExpanded(ancestorRow))
        compare(outline.view.activeFocus,true)
    }
    function test_columnsResizeWithoutChangingPath() {
        const model=source()
        const column=page("columns","workspaceColumns")
        model.selectedId="project-orbit"
        tryVerify(() => column.columns.length === 2)
        wait(0)
        const previous=column.columnWidthFor("")
        const handle=findChild(column,"macColumnHandle-")
        verify(handle !== null)
        verify(handle.height > 60)
        mousePress(handle,3,30)
        compare(handle.pressed,true)
        mouseMove(handle,43,30,40)
        mouseRelease(handle,43,30)
        tryVerify(() => column.columnWidthFor("") > previous+20)
        compare(model.selectedId,"project-orbit")
        compare(column.selectedPath.length,1)
        captureStep("09-column-resized")
        column.resizeColumn("",1)
        compare(column.columnWidthFor(""),144)
    }
    function test_outlineExpansionSurvivesModelUpdate() {
        const model=source()
        const outline=page("outline","workspaceOutline")
        outline.expandAll()
        tryVerify(() => outline.view.rows > 10)
        const previousRows=outline.view.rows
        const leaf=model.childrenFor("textures")[0].itemId
        verify(model.renameItem(leaf,"Revised material"))
        tryCompare(outline.view,"rows",previousRows)
    }
    function test_splitCollapseAndRestore() {
        const split=page("split","workspaceSplit")
        const inspector=split.itemAt(2)
        const previous=inspector.width
        verify(previous > 0)
        findChild(app,"splitMetadata").header.forceActiveFocus()
        split.setPaneCollapsed(2,true)
        tryCompare(split.itemAt(0),"activeFocus",true)
        compare(inspector.visible,false)
        compare(split.isPaneCollapsed(2),true)
        split.restorePane(2)
        tryCompare(inspector,"visible",true)
        tryCompare(inspector,"width",previous)
        verify(split.itemAt(0).width >= split.itemAt(0).SplitView.minimumWidth)
    }
    function test_tabsKeepLiveDraft() {
        const tabs=page("tabs","workspaceTabs")
        tryVerify(() => tabs.pageAt(0)!==null)
        const overview=tabs.pageAt(0)
        const editor=findChild(overview,"tabDraft-overview")
        editor.forceActiveFocus(); keyClick("N"); keyClick("o"); keyClick("t"); keyClick("e")
        compare(editor.text,"Note")
        captureStep("04-entered-draft")
        mouseClick(findChild(tabs,"macTab-build"))
        compare(app.currentTab,"build")
        captureStep("05-switched-page")
        mouseClick(findChild(tabs,"macTab-overview"))
        compare(app.currentTab,"overview")
        compare(tabs.pageAt(0),overview)
        compare(editor.text,"Note")
        captureStep("06-retained-draft")
    }
    function test_disclosureKeyboardRetainsContent() {
        const view=page("disclosure")
        const group=findChild(view,"exportDisclosure")
        compare(group.expanded,false)
        group.header.forceActiveFocus()
        keyClick(Qt.Key_Space)
        tryCompare(group,"expanded",true)
        tryVerify(() => group.height >= group.header.height + group.contentItem.implicitHeight)
        const format = accessibleChild(group,"Export format")
        verify(format !== null)
        format.forceActiveFocus(); keyClick(Qt.Key_Down)
        compare(format.currentIndex,1)
        captureStep("07-keyboard-expanded")
        group.header.forceActiveFocus()
        keyClick(Qt.Key_Space)
        tryCompare(group,"expanded",false)
        tryCompare(group,"height",group.header.height)
        captureStep("08-keyboard-collapsed")
        keyClick(Qt.Key_Space)
        tryCompare(group,"expanded",true)
        compare(format.currentIndex,1)
    }
    function test_longTabsRemainReachableWithKeyboard() {
        const tabs=page("tabs","workspaceTabs")
        tabs.tabs=[{key:"overview",title:"Обзор большого рабочего пространства"},
                   {key:"build",title:"Настройки сборки и предварительного просмотра"},
                   {key:"history",title:"История изменений и связанные материалы"}]
        app.width=800
        const first=findChild(tabs,"macTab-overview")
        first.forceActiveFocus()
        keyClick(Qt.Key_End)
        tryCompare(app,"currentTab","history")
        const last=findChild(tabs,"macTab-history")
        tryCompare(last,"activeFocus",true)
        tryVerify(() => last.mapToItem(tabs,0,0).x >= -1
            && last.mapToItem(tabs,last.width,0).x <= tabs.width+1)
    }
    function test_tenThousandItemsRemainVirtualized() {
        const model=source()
        model.generateItems(10000)
        const collection=findChild(app,"workspaceCollection")
        tryCompare(collection,"itemCount",10000)
        const grid=findChild(collection,"macCollectionGrid")
        verify(grid !== null)
        verify(waitForRendering(grid))
        verify(grid.contentItem.children.length < 150)
        collection.forceActiveFocus(); keyClick(Qt.Key_End)
        compare(model.selectedId,model.entries.itemIdAt(9999))
        wait(0)
        verify(grid.contentItem.children.length < 150)
    }
}
