// qml/Components/WidgetPopup.qml

import QtQuick
import Quickshell
import "../Colors"
import "../Config"

PopupWindow {
    id: root

    required property var widget

    default property alias content: contentItem.data
    property real contentMargins: 10

    // true (default): popup is horizontally centered under/above the pill
    // and evenly rounded, like Clipboard/Audio/Battery/etc.
    // false: popup is left-aligned with the pill, and the corner touching
    // the pill squares off instead, like the app launcher.
    property bool centered: true
    property real cornerRadius: 20

    // When the bar sits at the bottom of the screen there's no room below
    // the widget, so the popup has to open upward instead of downward.
    readonly property bool barAtBottom: Config.barOrientation === "bottom"

    anchor.item: widget
    anchor.edges: (barAtBottom ? Edges.Top : Edges.Bottom) | (centered ? 0 : Edges.Left)
    anchor.gravity: (barAtBottom ? Edges.Top : Edges.Bottom) | (centered ? Edges.HCenter : Edges.Left)
    anchor.margins.top: 0
    anchor.margins.bottom: 0

    color: "transparent"

    // Keep the window mapped while there's any animation left to show, and
    // drop it only once we've fully settled back to closed.
    visible: widget.openProgress > 0.001 || widget.isOpenHere

    Item {
        anchors.fill: parent

        Rectangle {
            id: panel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: root.barAtBottom ? undefined : parent.top
            anchors.bottom: root.barAtBottom ? parent.bottom : undefined
            height: parent.height

            // Grows out of the edge nearest the pill, scaling and sliding
            // into place with a springy overshoot instead of a flat fade.
            transformOrigin: root.barAtBottom ? Item.Bottom : Item.Top
            scale: 0.85 + 0.15 * widget.openProgress
            opacity: widget.openProgress
            y: root.barAtBottom
                ? (1 - widget.openProgress) * 14
                : (1 - widget.openProgress) * -14

            // The corner that actually touches the pill squares off so the
            // pill and popup read as one shape. Only relevant when
            // left-aligned; centered popups don't touch a corner.
            topLeftRadius: (!root.centered && !root.barAtBottom) ? 0 : root.cornerRadius
            topRightRadius: root.cornerRadius
            bottomLeftRadius: (!root.centered && root.barAtBottom) ? 0 : root.cornerRadius
            bottomRightRadius: root.cornerRadius

            color: Colors.colors.backgroundAlt
            border.color: Colors.colors.background
            border.width: 2

            HoverHandler {
                onHoveredChanged: hovered ? root.widget.open() : root.widget.close()
            }

            Item {
                id: contentItem
                anchors.fill: parent
                anchors.margins: root.contentMargins
                // Fade the contents in slightly after the panel itself, so
                // the shape leads and the content follows.
                opacity: Math.max(0, (widget.openProgress - 0.25) / 0.75)
            }
        }
    }
}
