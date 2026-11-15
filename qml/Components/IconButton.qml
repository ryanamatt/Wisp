// qml/GraphingCalculator/IconButton.qml

import QtQuick
import "../Colors"

// Round icon button with hover and press feedback.
Rectangle {
    id: root

    property string icon: ""
    property color tint: Colors.colors.foregroundMuted
    property color hoverColor: Colors.colors.hover
    property color tintOnHover: root.tint
    property int iconSize: 18

    signal clicked

    implicitWidth: 30
    implicitHeight: 30
    radius: width / 2
    color: area.pressed ? Colors.colors.pressed
        : area.containsMouse ? root.hoverColor
        : "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    TintedIcon {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        name: root.icon
        tint: area.containsMouse ? root.tintOnHover : root.tint
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
