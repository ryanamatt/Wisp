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
    spacing: 10

    readonly property int maxPartitionsPerRow: 4

    readonly property var partitionRows: {
        var rows = []
        var parts = SystemMonitor.partitions
        for (var i = 0; i < parts.length; i += root.maxPartitionsPerRow) {
            rows.push(parts.slice(i, i + root.maxPartitionsPerRow))
        }
        return rows
    }

    component HSpacer : Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 5
        Layout.leftMargin: 25
        Layout.rightMargin: 25

        color: Colors.colors.shadow
        radius: 10
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        text: "System Monitor"
        font.family: "Iosevka Nerd Font Propo"
        font.pixelSize: 25
        color: Colors.colors.foregroundMuted
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 40

        Text {
            Layout.alignment: Qt.AlignHCenter

            text: "Uptime: " + Utils.formatUptime(SystemMonitor.uptimeSeconds)
            font.family: "Iosevka Nerd Font Propo"
            font.pixelSize: 20
            color: Colors.colors.foregroundMuted
            opacity: 0.7
        }

        Text {
            Layout.alignment: Qt.AlignHCenter

            text: "Load: " + Utils.formatLoad(SystemMonitor.loadAvg1)
                + "  " + Utils.formatLoad(SystemMonitor.loadAvg5)
                + "  " + Utils.formatLoad(SystemMonitor.loadAvg15)
            font.family: "Iosevka Nerd Font Propo"
            font.pixelSize: 20
            color: Colors.colors.foregroundMuted
            opacity: 0.7
        }
    }

    ScrollView {
        id: scrollView

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 10

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                spacing: 1

                MetricGroupCard {
                    title: "CPU"

                    MetricGauge {
                        label: "Temp"
                        value: SystemMonitor.cpuTemp
                        maxValue: 100
                        unit: "°C"
                        warnThreshold: 70
                        critThreshold: 85
                    }

                    MetricGauge {
                        label: "Usage"
                        value: SystemMonitor.cpuUsage
                        maxValue: 100
                        unit: "%"
                        warnThreshold: 70
                        critThreshold: 90
                    }
                }

                MetricGroupCard {
                    title: "GPU"

                    MetricGauge {
                        label: "Temp"
                        value: SystemMonitor.gpuTemp
                        maxValue: 100
                        unit: "°C"
                        warnThreshold: 70
                        critThreshold: 85
                    }

                    MetricGauge {
                        label: "Usage"
                        value: SystemMonitor.gpuUsage
                        maxValue: 100
                        unit: "%"
                        warnThreshold: 70
                        critThreshold: 90
                    }
                }

                MetricGroupCard {
                    title: "RAM"

                    MetricGauge {
                        label: "Usage"
                        value: SystemMonitor.memUsed / SystemMonitor.memTotal * 100
                        maxValue: 100
                        unit: "%"
                    }
                }
            }

            HSpacer {}

            Repeater {
                model: root.partitionRows

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Repeater {
                        model: modelData

                        MetricGroupCard {
                            title: modelData.mountpoint

                            MetricGauge {
                                label: "Used"
                                value: modelData.used / modelData.total * 100
                                maxValue: 100
                                unit: "%"
                                decimals: 1
                                warnThreshold: 80
                                critThreshold: 95
                            }
                        }
                    }
                }
            }

            HSpacer {}

        }
    }
}
