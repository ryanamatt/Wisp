// qml/GraphingCalculator/GraphGrid.qml

import QtQuick
import "../Colors"
import "../Config"
import "GraphFormat.js" as Fmt

// Grid lines, axes and number labels. Drawn behind the GraphView so the
// curves sit on top. Everything follows the GraphView viewport.
Item {
    id: root

    // The GraphView this grid follows
    required property var graph

    readonly property real step: graph.gridStep

    // Pixel position of the axes. They can sit off-screen when panned away.
    readonly property real axisX: graph.width / 2 - graph.centerX * graph.scale
    readonly property real axisY: graph.height / 2 + graph.centerY * graph.scale

    readonly property color gridColor: Qt.rgba(Colors.colors.border.r, Colors.colors.border.g, Colors.colors.border.b, 0.55)
    readonly property color axisColor: Colors.colors.borderStrong
    readonly property color labelColor: Colors.colors.foregroundSubtle

    // Vertical lines, x labels
    Repeater {
        model: Math.ceil((root.graph.xMax - root.graph.xMin) / root.step) + 2

        delegate: Item {
            id: vLine

            required property int index

            readonly property real value: (Math.floor(root.graph.xMin / root.step) + index) * root.step
            readonly property bool isAxis: Math.abs(value) < root.step * 1e-6
            readonly property real px: root.graph.width / 2 + (value - root.graph.centerX) * root.graph.scale

            Rectangle {
                x: vLine.px - width / 2
                width: vLine.isAxis ? 2 : 1
                height: root.height
                color: vLine.isAxis ? root.axisColor : root.gridColor
                z: vLine.isAxis ? 1 : 0
            }

            Text {
                visible: !vLine.isAxis
                text: Fmt.tick(vLine.value, root.step)
                x: vLine.px - width / 2
                // Stick to the edge when the x axis is panned off-screen
                y: Math.max(4, Math.min(root.axisY + 4, root.height - height - 4))
                color: root.labelColor
                font.family: Config.font
                font.pixelSize: 11
                style: Text.Outline
                styleColor: Colors.colors.surfaceInput
            }
        }
    }

    // Horizontal lines, y labels
    Repeater {
        model: Math.ceil((root.graph.yMax - root.graph.yMin) / root.step) + 2

        delegate: Item {
            id: hLine

            required property int index

            readonly property real value: (Math.floor(root.graph.yMin / root.step) + index) * root.step
            readonly property bool isAxis: Math.abs(value) < root.step * 1e-6
            readonly property real py: root.graph.height / 2 - (value - root.graph.centerY) * root.graph.scale

            Rectangle {
                y: hLine.py - height / 2
                height: hLine.isAxis ? 2 : 1
                width: root.width
                color: hLine.isAxis ? root.axisColor : root.gridColor
                z: hLine.isAxis ? 1 : 0
            }

            Text {
                text: Fmt.tick(hLine.value, root.step)
                // Stick to the edge when the y axis is panned off-screen
                x: Math.max(4, Math.min(root.axisX + 6, root.width - width - 4))
                // The origin label sits below the x axis so it does not hide behind it
                y: hLine.isAxis ? hLine.py + 4 : hLine.py - height / 2
                color: root.labelColor
                font.family: Config.font
                font.pixelSize: 11
                style: Text.Outline
                styleColor: Colors.colors.surfaceInput
            }
        }
    }
}

