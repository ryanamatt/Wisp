// qml/Bar/SystemMonitor/SystemMonitorWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../GlobalState"
import "../../Components"
import "../../Colors"
import Wisp.System

BarWidgetContainer {
    id: systemMonitorWidget

    required property var screen

    property var systemIconList: [
        {
            label: "cool",
            glyph: "\uf2cb",
            color: Colors.colors.success
        },
        {
            label: "medium",
            glyph: "\uf2c9",
            color: Colors.colors.warning
        },
        {
            label: "warm",
            glyph: "\uf2c7",
            color: Colors.colors.error
        }
    ]

    property var currentTempState: {
        let temp = SystemMonitor.cpuTemp;
        if (temp < 70) return systemIconList[0]
        if (temp < 90) return systemIconList[1]
        return systemIconList[2]
    }

    icon.font.pixelSize: implicitWidth * 0.125
    icon.text: currentTempState.glyph + SystemMonitor.cpuTemp + "°C|"+ SystemMonitor.cpuUsage.toFixed(1) + "%"
    icon.color: currentTempState.color

    isOpenHere: GlobalState.systemMonitorWidget.isOpenOn(systemMonitorWidget.screen)

    popupWindows: [monitorPopup]

    onRequestOpen: GlobalState.systemMonitorWidget.open(systemMonitorWidget.screen)
    onRequestClose: GlobalState.systemMonitorWidget.close()

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

    PopupWindow {
        id: monitorPopup

        anchor.item: systemMonitorWidget
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitHeight: 200
        implicitWidth: 400

        visible: systemMonitorWidget.openProgress > 0.001 || systemMonitorWidget.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * systemMonitorWidget.openProgress
                opacity: systemMonitorWidget.openProgress
                y: (1 - systemMonitorWidget.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            systemMonitorWidget.open()
                        } else {
                            systemMonitorWidget.close()
                        }
                    }
                }

                SystemMonitorPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (systemMonitorWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: systemMonitorWidget.forceClose()
                }
            }
        }
    }

}
