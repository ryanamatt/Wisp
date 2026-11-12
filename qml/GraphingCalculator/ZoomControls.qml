// qml/GraphingCalculator/ZoomControls.qml

import QtQuick
import QtQuick.Layouts
import "../Colors"

// Zoom in, zoom out and reset-view buttons.
Rectangle {
    id: root

    signal zoomIn
    signal zoomOut
    signal resetView

    // True while the cursor is over the controls (the hover readout hides then)
    readonly property bool hovered: hoverHandler.hovered

    implicitWidth: 38
    implicitHeight: column.implicitHeight + 8
    radius: 19
    color: Colors.colors.surfaceElevated
    border.width: 1
    border.color: Colors.colors.border

    HoverHandler {
        id: hoverHandler
    }

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 2

        IconButton {
            icon: "ui/zoomIn"
            onClicked: root.zoomIn()
        }

        IconButton {
            icon: "ui/zoomOut"
            onClicked: root.zoomOut()
        }

        IconButton {
            icon: "ui/fitScreen"
            onClicked: root.resetView()
        }
    }
}


