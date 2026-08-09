// qml/Bar/SystemMonitor/SystemMonitorPopup.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"
import "../../Components"
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
            spacing: 8

        MonitorLayout {
            id: cpuLayout

            icon: "\uf2db"
            name: "CPU"
            beforeBarText: SystemMonitor.cpuTemp + "°C"
            afterBarText: SystemMonitor.cpuUsage.toFixed(1) + "%"
            barValue: SystemMonitor.cpuUsage
            warnAt: 60
            critAt: 85
        }

        MonitorLayout {
            id: gpuLayout

            icon: "\uf2db"
            name: "GPU"
            beforeBarText: SystemMonitor.gpuTemp + "°C"
            afterBarText: SystemMonitor.gpuUsage.toFixed(1) + "%"
            barValue: SystemMonitor.gpuUsage
            warnAt: 80
            critAt: 90
        }

        MonitorLayout {
            id: memoryLayout

            icon: "\udb80\udf5b"
            name: "MEM"
            afterBarText: Utils.formatSizePair(SystemMonitor.memUsed, SystemMonitor.memTotal)
            barValue: (SystemMonitor.memUsed / SystemMonitor.memTotal) * 100
        }

        Repeater {
            model: SystemMonitor.partitions

            MonitorLayout {
                required property var modelData

                icon: "\uf0a0"
                name: modelData.mountpoint  === "/" ? "disk" : modelData.mountpoint
                afterBarText: Utils.formatSizePair(modelData.used, modelData.total)
                barValue: modelData.total > 0 ? (modelData.used / modelData.total) * 100 : -1
            }
        }


        } // contentLayout

    } // ScrollView

}