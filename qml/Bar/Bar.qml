// qml/bar/Bar.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Colors"
import "TimeWorkspace"
import "AppLauncher"
import "PowerMenu"
import "Notifications"
import "Audio"
import "Weather"
import "SystemMonitor"
import "Clipboard"
import "Network"
import "Brightness"
import "Battery"

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

            Item { implicitWidth: 20}

            SystemMonitorWidget { screen: bar.modelData }

            Item { implicitWidth: 20 }

            NetworkWidget { screen: bar.modelData }

            Item { implicitWidth: 50 }

            BrightnessWidget { screen: bar.modelData }

            Item { implicitWidth: 20 }

            BatteryWidget { screen: bar.modelData }

            Item { Layout.fillWidth: true }

            Item { implicitWidth: 95 }

            // Width 50
            PowerMenuWidget {
                screen: bar.modelData
            }

            Item { implicitWidth: 20 }

            TimeWorkspaceWidget {
                screen: bar.modelData
                Layout.alignment: Qt.AlignHCenter
            }

            Item  {implicitWidth: 20 }

            WeatherWidget {}

            Item  {implicitWidth: 20 }

            AudioWidget {}

            Item { implicitWidth: 125 }

            Item { Layout.fillWidth: true }

            ClipboardWidget { screen: bar.modelData }

            Item {implicitWidth: 20 }

            NotificationsWidget {}
        }
    }
}