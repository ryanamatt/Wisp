// qml/Screenshot/ScreenshotTab.qml

import QtQuick
import QtQuick.Window
import "../Colors"

Item {
    id: screenshotTab

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Colors.colors.background
        border.color: Colors.colors.border
        border.width: 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => screenshotTab.Window.window.startSystemMove()
            onClicked: (mouse) => mouse.accepted = true
        }
    }
}