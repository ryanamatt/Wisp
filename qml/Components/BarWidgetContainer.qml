// qml/Components/BarWidgetContainer

import QtQuick
import "../Colors"

Rectangle {
    id: container

    color: Colors.colors.backgroundAlt
    border.color: Colors.colors.background

    implicitHeight: 40

    border.width: 2
    radius: implicitHeight / 2

    default property alias content: container.data

    property alias icon: icon
    Text {
        id: icon
        anchors.centerIn: parent
        color: Colors.colors.foreground
        font.pixelSize: 25
        font.family: "Noto Sans Mono"
    }

}