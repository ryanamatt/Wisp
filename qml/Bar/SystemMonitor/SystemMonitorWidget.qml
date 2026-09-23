// qml/Bar/SystemMonitor/SystemMonitorWidget.qml

import QtQuick
import Quickshell
import "../../IpcState"
import "../../Components"
import "../../Colors"
import Wisp.System

BarWidgetContainer {
    id: systemMonitorWidget

    required property var screen

    property var systemIconList: [
        { label: "cool", color: Colors.colors.success },
        { label: "medium", color: Colors.colors.warning },
        { label: "warm", color: Colors.colors.error }
    ]

    property var currentTempState: {
        let temp = SystemMonitor.cpuTemp;
        if (temp < 70) return systemIconList[0]
        if (temp < 90) return systemIconList[1]
        return systemIconList[2]
    }

    iconText.font.pixelSize: implicitWidth * 0.13
    iconText.text: SystemMonitor.cpuTemp + "°C|"+ SystemMonitor.cpuUsage.toFixed(1) + "%"
    iconText.color: currentTempState.color

    isOpenHere: IpcState.systemMonitorWidget.isOpenOn(systemMonitorWidget.screen)

    popupWindows: [monitorPopup]

    onRequestOpen: IpcState.systemMonitorWidget.open(systemMonitorWidget.screen)
    onRequestClose: IpcState.systemMonitorWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.resetSelection()
            popup.forceActiveFocus()
            activateFocusGrab()
        } else {
            popup.closePopup()
            releaseFocusGrab()
        }
    }

    WidgetPopup {
        id: monitorPopup
        widget: systemMonitorWidget
        implicitWidth: 400
        implicitHeight: 200

        SystemMonitorPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: systemMonitorWidget.forceClose()
        }
    }
}
