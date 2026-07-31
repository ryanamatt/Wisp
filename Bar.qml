// Bar.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "Colors"
import "TimeWorkspace"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData

        color: "#000000"

        anchors { top: true; left: true; right: true; }
        implicitHeight: 40

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 0

            Item { Layout.fillWidth: true }

            TimeWorkspaceWidget {
                screen: bar.modelData
                Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillWidth: true }

        }
    }
}