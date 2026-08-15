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
            id: rowLayout
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 0

            // Math Based on a 1920x1080 Monitor

            // ~3.95% (75px)
            AppsWidget { 
                screen: bar.modelData 
                implicitWidth: rowLayout.width * (75 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (20 / 1900) }

            // ~6.32% (120px)
            SystemMonitorWidget { 
                screen: bar.modelData 
                implicitWidth: rowLayout.width * (120 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (20 / 1900) }

            // ~2.63% (50px)
            NetworkWidget { 
                screen: bar.modelData 
                implicitWidth: rowLayout.width * (50 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (50 / 1900) }

            // ~2.63% (50px)
            BrightnessWidget { 
                screen: bar.modelData 
                implicitWidth: rowLayout.width * (100 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (20 / 1900) }

            // ~5.26% (100px)
            BatteryWidget { 
                screen: bar.modelData 
                implicitWidth: rowLayout.width * (100 / 1900)
            }

            Item { Layout.fillWidth: true }

            Item { implicitWidth: rowLayout.width * (95 / 1900) }

            // Adjusted from 20 to 30 to account for the extra 20px centering offset
            Item { implicitWidth: rowLayout.width * (30 / 1900) }

            // ~2.63% (50px)
            PowerMenuWidget { 
                screen: bar.modelData 
                implicitWidth: rowLayout.width * (50 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (20 / 1900) }

            // ~10.53% (200px) - Perfectly centered now
            TimeWorkspaceWidget {
                screen: bar.modelData
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 200
                // implicitWidth: rowLayout.width * (200 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (20 / 1900) }

            // ~3.95% (75px)
            WeatherWidget {
                implicitWidth: rowLayout.width * (75 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (20 / 1900) }

            // ~11.58% (220px)
            AudioWidget {
                implicitWidth: rowLayout.width * (220 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (300 / 1900) }

            Item { Layout.fillWidth: true }

            // ~2.63% (50px)
            ClipboardWidget { 
                screen: bar.modelData 
                implicitWidth: rowLayout.width * (50 / 1900)
            }

            Item { implicitWidth: rowLayout.width * (20 / 1900) }

            // ~2.63% (50px)
            NotificationsWidget {
                implicitWidth: rowLayout.width * (50 / 1900)
            }
        }
    }
}