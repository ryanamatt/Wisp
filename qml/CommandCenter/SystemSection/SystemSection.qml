// qml/CommandCenter/SystemSection/SystemSection.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"
import "../../Components"
import "../../Utils/Utils.js" as Utils
import Wisp.System

ColumnLayout {
    id: root

    anchors.fill: parent
    clip: true
    spacing: 20

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        text: "System Monitor"
        font.family: "Iosevka Nerd Font Propo"
        font.pixelSize: 25
        color: Colors.colors.foregroundMuted
    }
}