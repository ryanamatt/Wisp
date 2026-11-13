// qml/GraphingCalculator/TintedIcon.qml

import QtQuick
import QtQuick.Effects
import "../Colors"
import "../Icons"

// Tints an Icon to Match Theme
Item {
    id: root

    property string name: ""
    property color tint: Colors.colors.foreground

    implicitWidth: 18
    implicitHeight: 18

    Image {
        id: iconImage
        anchors.fill: parent
        source: root.name !== "" ? Icons.getIcon(root.name) : ""
        sourceSize: Qt.size(64, 64)
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: iconImage
        brightness: 1.0
        colorization: 1.0
        colorizationColor: root.tint
    }
}

