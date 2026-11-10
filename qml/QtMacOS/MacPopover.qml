pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Popup {
    id: popover
    property Item anchorItem: null
    property real edgeMargin: 16
    property bool preferAbove: false
    property bool requestedVisible: false
    readonly property Item viewport: anchorItem && anchorItem.Window.window ? anchorItem.Window.window.contentItem : null
    property point anchorPosition: Qt.point(0, 0)
    function updatePlacement() {
        if (anchorItem && viewport)
            // Use layout geometry: the anchor's press/release scale must not
            // displace the popup, nor be inherited by its coordinate system.
            anchorPosition = anchorItem.parent.mapToItem(viewport, anchorItem.x, anchorItem.y);
    }
    readonly property bool above: (preferAbove || (viewport && anchorPosition.y + anchorItem.height + height + 10 > viewport.height - edgeMargin))
        && anchorPosition.y >= height + edgeMargin + 10
    readonly property real viewportX: viewport
        ? Math.max(edgeMargin, Math.min(viewport.width - width - edgeMargin,
                     anchorPosition.x + (anchorItem ? anchorItem.width / 2 : 0) - width / 2)) : 0
    readonly property real viewportY: viewport
        ? Math.max(edgeMargin, Math.min(viewport.height - height - edgeMargin,
              above ? anchorPosition.y - height - 10 : anchorPosition.y + anchorItem.height + 10)) : 0
    // An unscaled anchor proxy preserves Qt's outside-parent dismissal while
    // keeping the popup independent of the real button's press transform.
    readonly property Item placementAnchor: Item {
        parent: popover.viewport
        x: popover.anchorPosition.x
        y: popover.anchorPosition.y
        width: popover.anchorItem ? popover.anchorItem.width : 0
        height: popover.anchorItem ? popover.anchorItem.height : 0
    }
    parent: placementAnchor
    x: viewportX - anchorPosition.x
    y: viewportY - anchorPosition.y
    margins: edgeMargin
    padding: 18
    focus: true
    modal: false
    // Clicking the anchor is handled by its own toggle. Other outside clicks
    // dismiss and can immediately activate another control.
    closePolicy: Basic.Popup.CloseOnEscape | Basic.Popup.CloseOnPressOutsideParent
    transformOrigin: Item.Center
    enter: MacPopupTransition {}
    exit: MacPopupTransition { appearing: false }
    function toggle() { if (requestedVisible) close(); else open(); }
    onAboutToShow: {
        updatePlacement();
        requestedVisible = true;
    }
    onAboutToHide: requestedVisible = false
    onClosed: {
        if (anchorItem && anchorItem.visible && anchorItem.enabled && viewport) {
            const current = anchorItem.Window.window.activeFocusItem;
            // Preserve focus taken by a newly opened dialog or outside control.
            if (!current || current === viewport || current === anchorItem)
                anchorItem.forceActiveFocus(Qt.PopupFocusReason);
        }
    }
    Connections {
        target: popover.anchorItem
        function onVisibleChanged() { if (!popover.anchorItem || !popover.anchorItem.visible) popover.close(); }
    }
    Connections {
        target: popover.viewport
        function onWidthChanged() { if (popover.visible) Qt.callLater(popover.updatePlacement); }
        function onHeightChanged() { if (popover.visible) Qt.callLater(popover.updatePlacement); }
    }
    background: Rectangle {
        radius: 12
        color: Theme.settingsGroup
        border.color: Theme.border
        antialiasing: true
        Rectangle {
            id: pointer
            x: Math.max(18, Math.min(parent.width - width - 18,
                popover.anchorPosition.x + (popover.anchorItem ? popover.anchorItem.width / 2 : 0) - popover.viewportX - width / 2))
            y: popover.above ? parent.height - height / 2 - 1 : -height / 2 + 1
            width: 12; height: 12; rotation: 45
            color: parent.color
            border.color: Theme.border
            antialiasing: true
        }
        // Cover the pointer's inner border where it meets the main surface.
        Rectangle {
            x: pointer.x - 4; y: popover.above ? parent.height - 10 : 0
            width: pointer.width + 8; height: 10
            color: parent.color
        }
    }
}
