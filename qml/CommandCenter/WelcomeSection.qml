// qml/CommandCenter/WelcomeSection.qml

import QtQuick
import QtQuick.Layouts
import "../Colors"

ColumnLayout {
    id: root

    anchors.fill: parent
    clip: true
    spacing: 20

    Rectangle {
        id: welcomeBanner

        Layout.fillWidth: true
        Layout.maximumWidth: welcomeText.width + 25
        Layout.preferredHeight: 45
        Layout.alignment: Qt.AlignHCenter

        color: Colors.colors.surfaceAlt
        border.color: Colors.colors.border
        border.width: 2
        radius: welcomeBanner.width / 2

        Text {
            id: welcomeText
            text: "Welcome to Wisp"
            font.family: "Iosevka Nerd Font Propo"
            font.pixelSize: 25
            color: Colors.colors.accentAlt
            anchors.centerIn: parent
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
