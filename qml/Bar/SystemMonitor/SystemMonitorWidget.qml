// qml/Bar/SystemMonitor/SystemMonitorWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../Components"
import "../../Colors"
import Wisp.System

BarWidgetContainer {
    id: systemMonitorWidget

    required property var screen

    implicitWidth: 100

    icon.font.pixelSize: 15
    // icon.text: SystemMonitor.cpuTemp + " | " + SystemMonitor.cpuUsage
    icon.text: SystemMonitor.memUsed + " | " + SystemMonitor.memTotal
}
