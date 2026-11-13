// qml/GraphingCalculator/IconButton.qml

import QtQuick
import "../Colors"

// Round icon button with hover and press feedback.
Rectangle {
    id: root

    property string icon: ""
    property color tint: Colors.colors.foregroundMuted
    property int iconSize: 18

    signal clicked

    implicitWidth: 30
    implicitHeight: 30
    radius: width / 2
    color: area.pressed ? Colors.colors.pressed : area.containsMouse ? Colors.colors.hover : "transparent"

    TintedIcon {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        name: root.icon
        tint: root.tint
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
