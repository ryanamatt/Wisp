// qml/bar/Bar.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Colors"
import "TimeWorkspace"
import "AppLauncher"
import "PowerMenu"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData

        color: Qt.rgba(Colors.colors.surfaceAlt.r, Colors.colors.surfaceAlt.g, Colors.colors.surfaceAlt.b, 0.2)

        anchors { top: true; left: true; right: true; }
        implicitHeight: 40

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 0

            // Width 75
            AppsWidget { screen: bar.modelData }

            Item { Layout.fillWidth: true }

            // Width 50
            PowerMenuWidget {}

            Item { implicitWidth: 20 }

            TimeWorkspaceWidget {
                screen: bar.modelData
                Layout.alignment: Qt.AlignHCenter
            }

            Item { implicitWidth: 70 }

            Item { Layout.fillWidth: true }

            // Width 75
            Item { implicitWidth: 75 }

        }
    }
}