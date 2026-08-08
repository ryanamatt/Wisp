// qml/Bar/SystemMonitor/SystemMonitorPopup.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"
import "../../Components"
import Wisp.System

BarPopup {
    id: monitorPopup

    signal requestClose()

    property int currentIndex: 0

    function resetSelection() {
        monitorPopup.currentIndex = 0
    }

    function closePopup() {
        resetSelection()
    }

    // Small helper so every bar's fill color reacts to how "hot" the stat is
    function levelColor(percent, warnAt, critAt) {
        if (percent >= critAt) return Colors.colors.error
        if (percent >= warnAt) return Colors.colors.warning
        return Colors.colors.accent
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        contentWidth: availableWidth

        ColumnLayout {
            id: contentLayout
            width: parent.width
            spacing: 8

            ColumnLayout {
                id: cpuLayout
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {

                        Text {
                            text: "\uf2db" // microchip icon
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 22
                            color: Colors.colors.foreground
                        }

                        Text {
                            text: "CPU"
                            color: Colors.colors.foreground
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    Text {
                        text: SystemMonitor.cpuTemp + "°C"
                        color: currentTempState.color
                        font.pixelSize: 14
                    }

                    UsageBar {
                        Layout.fillWidth: true
                        barColor: Colors.colors.foregroundMuted
                        barFillColor: monitorPopup.levelColor(SystemMonitor.cpuUsage, 60, 85)
                        value: SystemMonitor.cpuUsage
                    }

                    Text {
                        text: SystemMonitor.cpuUsage.toFixed(1) + "%"
                        color: Colors.colors.foreground
                        font.pixelSize: 12
                    }
                }
            } // cpuLayout



        } // contentLayout

    } // ScrollView

}