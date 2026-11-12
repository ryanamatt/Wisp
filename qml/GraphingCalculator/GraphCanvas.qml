// qml/GraphingCalculator/GraphCanvas.qml

import QtQuick
import QtQuick.Effects
import "../Colors"
import Wisp.Calculator

// The plot area: grid, curves (GraphView from the C++ backend), hover readout
// and zoom buttons. Drag to pan and scroll to zoom are built into GraphView.
Item {
    id: root

    // Hand GraphFunctions to this (graph.addFunction / removeFunction)
    readonly property alias graph: view

    readonly property real zoomFactor: 1.25

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 12
        color: Colors.colors.surfaceInput
        border.width: 1
        border.color: Colors.colors.border
    }

    // Rounded-corner mask so the grid and curves do not poke out of the frame
    Item {
        id: mask
        anchors.fill: plot
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: frame.radius - 1
            color: "black"
        }
    }

    Item {
        id: plot
        anchors.fill: frame
        anchors.margins: 1
        // Plain rectangular clip as a fallback underneath the rounded mask
        clip: true

        // Multisampling smooths the curve edges
        layer.enabled: true
        layer.samples: 4
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
        }

        GraphView {
            id: view
            anchors.fill: parent
            lineWidth: 2.5
        }

    }
}

