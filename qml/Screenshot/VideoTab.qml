// qml/Screenshot/VideoTab.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"

Item {
    id: videoTab

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Colors.colors.background
        border.color: Colors.colors.border
        border.width: 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => videoTab.Window.window.startSystemMove()
            onClicked: (mouse) => mouse.accepted = true
        }

        Text {
            anchors.centerIn: parent

            color: Colors.colors.accent
            text: "Coming Soon"
            font.bold: true
        }
    }
}