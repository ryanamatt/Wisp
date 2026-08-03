// qml/Components/BarWidgetContainer

import QtQuick
import "../Colors"

Rectangle {
    id: container

    color: Colors.colors.backgroundAlt
    border.color: Colors.colors.background

    border.width: 2
    radius: implicitHeight / 2

    default property alias content: container.data
}