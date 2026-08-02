// qml/TimeWorkspace/TimeWorkspaceWidget.qml

import QtQuick
import QtQuick.Layouts
import "../../Colors"
import Wisp.Time

Rectangle {

    id: timeWorkspace

    required property var screen

    color: Colors.colors.backgroundAlt
    border.color: Colors.colors.background
    border.width: 2

    implicitWidth: 200
    implicitHeight: 40

    radius: implicitWidth / 2

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4 // Space between time and indicators

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Time.time
            color: Colors.colors.foreground
            font.pixelSize: 14
            font.family: "Noto Sans Mono"
        }

        WorkspaceIndicator { 
            screen: timeWorkspace.screen 
            Layout.alignment: Qt.AlignHCenter
        }
    }
}