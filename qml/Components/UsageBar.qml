// qml/Components/UsageBar.qml

import QtQuick

Rectangle {
    id: root

    property real value: 0.0
    property color barColor: "#000000"
    property color barFillColor: "#FFFFFF"

    height: 6
    radius: 3
    color: root.barColor

    Rectangle {
        width: parent.width * Math.max(0.0, Math.min(1.0, root.value / 100.0))
        height: parent.height
        radius: parent.radius
        color: root.barFillColor
    }
}