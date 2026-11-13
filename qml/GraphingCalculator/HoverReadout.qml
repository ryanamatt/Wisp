// qml/GraphingCalculator/HoverReadout.qml

import QtQuick
import QtQuick.Layouts
import "../Colors"
import "../Config"
import "GraphFormat.js" as Fmt

// Shows a dot on every curve at the cursor's x, plus a small card with the
// cursor coordinates and each curve's y value.
Item {
    id: root

    required property var graph

    // True while the cursor is over the plot
    property bool active: false
    // Cursor position in item pixels
    property point point: Qt.point(0, 0)

    // Same math as GraphView.toGraphX/Y, written out so bindings re-run on pan and zoom
    readonly property real graphX: graph.centerX + (point.x - graph.width / 2) / graph.scale
    readonly property real graphY: graph.centerY - (point.y - graph.height / 2) / graph.scale

    visible: active

    // Dots on the curves
    Repeater {
        model: root.active ? root.graph.functions : []

        delegate: Rectangle {
            id: dot

            required property var modelData

            readonly property real value: modelData.valid && modelData.visible ? modelData.evaluate(root.graphX) : NaN

            visible: isFinite(value)
            width: 10
            height: 10
            radius: 5
            color: modelData.color
            border.width: 2
            border.color: Colors.colors.surfaceInput
            x: root.point.x - width / 2
            y: root.graph.height / 2 - (value - root.graph.centerY) * root.graph.scale - height / 2
        }
    }

    // Value card
    Rectangle {
        id: card

        // Keep the card on screen by flipping it to the other side of the cursor
        x: root.point.x + 16 + width > root.width - 8 ? root.point.x - 16 - width : root.point.x + 16
        y: root.point.y + 16 + height > root.height - 8 ? root.point.y - 16 - height : root.point.y + 16

        implicitWidth: content.implicitWidth + 20
        implicitHeight: content.implicitHeight + 16
        width: implicitWidth
        height: implicitHeight
        radius: 10
        color: Colors.colors.surfaceElevated
        border.width: 1
        border.color: Colors.colors.border

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: "x = " + Fmt.coord(root.graphX, root.graph.gridStep) + "    y = " + Fmt.coord(root.graphY, root.graph.gridStep)
                color: Colors.colors.foreground
                font.family: Config.font
                font.pixelSize: 12
            }

            Repeater {
                model: root.active ? root.graph.functions : []

                delegate: RowLayout {
                    id: entry

                    required property var modelData

                    readonly property real value: modelData.valid && modelData.visible ? modelData.evaluate(root.graphX) : NaN

                    visible: modelData.valid && modelData.visible
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: entry.modelData.color
                    }

                    Text {
                        text: "y = " + Fmt.number(entry.value)
                        color: Colors.colors.foregroundMuted
                        font.family: Config.font
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}

