// qml/Bar/SystemMonitor/SystemMonitorPopup.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../../Colors"
import "../../Components"
import "../../Config"
import "../../Icons"
import "../../Utils/Utils.js" as Utils
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

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        contentWidth: availableWidth

        ColumnLayout {
            id: contentLayout
            width: parent.width
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                RowLayout {
                    spacing: 4

                    Image {
                        source: Icons.getIcon("arrowDown")
                        sourceSize.width: width * Screen.devicePixelRatio
                        sourceSize.height: height * Screen.devicePixelRatio

                        Layout.preferredWidth: rxText.height * 0.8
                        Layout.preferredHeight: rxText.height * 0.8

                        fillMode: Image.PreserveAspectFit

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: Colors.colors.info
                        }
                    }

                    Text {
                        id: rxText
                        text: Utils.formatRate(SystemMonitor.netRxBytesPerSec)
                        font.pixelSize: 16
                        font.family: Config.font
                        color: Colors.colors.foreground
                    }
                }

                RowLayout {
                    spacing: 4

                    Image {
                        source: Icons.getIcon("arrowUp")
                        sourceSize.width: width * Screen.devicePixelRatio
                        sourceSize.height: height * Screen.devicePixelRatio

                        Layout.preferredWidth: txText.height * 0.8
                        Layout.preferredHeight: txText.height * 0.8

                        fillMode: Image.PreserveAspectFit

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: Colors.colors.warning
                        }
                    }

                    Text {
                        id: txText
                        text: Utils.formatRate(SystemMonitor.netTxBytesPerSec)
                        font.pixelSize: 16
                        font.family: Config.font
                        color: Colors.colors.foreground
                    }
                }

            }

            MonitorLayout {
                id: cpuLayout

                icon: Icons.getIcon("devBoard")
                name: "CPU"
                beforeBarText: SystemMonitor.cpuTemp + "°C"
                afterBarText: SystemMonitor.cpuUsage.toFixed(1) + "%"
                barValue: SystemMonitor.cpuUsage
                warnAt: 60
                critAt: 85
            }

            MonitorLayout {
                id: gpuLayout

                icon: Icons.getIcon("devBoard")
                name: "GPU"
                beforeBarText: SystemMonitor.gpuTemp + "°C"
                afterBarText: SystemMonitor.gpuUsage.toFixed(1) + "%"
                barValue: SystemMonitor.gpuUsage
                warnAt: 80
                critAt: 90
            }

            MonitorLayout {
                id: memoryLayout

                icon: Icons.getIcon("memory")
                name: "MEM"
                afterBarText: Utils.formatSizePair(SystemMonitor.memUsed, SystemMonitor.memTotal)
                barValue: (SystemMonitor.memUsed / SystemMonitor.memTotal) * 100
            }

            Repeater {
                model: SystemMonitor.partitions

                MonitorLayout {
                    required property var modelData

                    icon: Icons.getIcon("hardDrive")
                    name: modelData.mountpoint  === "/" ? "disk" : modelData.mountpoint
                    afterBarText: Utils.formatSizePair(modelData.used, modelData.total)
                    barValue: modelData.total > 0 ? (modelData.used / modelData.total) * 100 : -1
                }
            }


        } // contentLayout

    } // ScrollView

}
