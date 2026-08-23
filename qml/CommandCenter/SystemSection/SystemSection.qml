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

    RowLayout {

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

    }

    Item {
        Layout.fillHeight: true
    }


}
