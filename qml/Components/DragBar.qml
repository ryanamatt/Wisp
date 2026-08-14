// qml/Components/DragBar.qml

import QtQuick
import "../Colors"

Item {
    id: bar

    property real value: 0 // 0..1
    property bool enabled: true
    property color fillColor: Colors.colors.accent

    signal moved(real newValue)

    implicitHeight: 14

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Colors.colors.surface
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(6, bar.width * Math.max(0, Math.min(1, bar.value)))
        height: 6
        radius: 3
        color: bar.enabled ? bar.fillColor : Colors.colors.borderSoft
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: bar.enabled
        cursorShape: bar.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        function updateFromMouse(x) {
            const ratio = Math.max(0, Math.min(1, x / bar.width))
            bar.value = ratio
            bar.moved(ratio)
        }

        onPressed: mouse => updateFromMouse(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                updateFromMouse(mouse.x)
        }
    }
}