// qml/bar/TimeWorkspace/TimeWorkspaceWidget.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../Components"
import "../../GlobalState"
import "../../Colors"
import Wisp.Time

BarWidgetContainer {
    id: timeWorkspace

    required property var screen

    implicitWidth: 200

    radius: implicitWidth / 2

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4 // Space between time and indicators

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Time.time
            color: Colors.colors.foreground
            font.pixelSize: 14
            font.family: "Noto Sans Mono"
        }

        WorkspaceIndicator { 
            screen: timeWorkspace.screen 
            Layout.alignment: Qt.AlignHCenter
        }
    }

    isOpenHere: GlobalState.timeWorkspace.isOpenOn(timeWorkspace.screen)

    popupWindows: [calendarPopup]

    onRequestOpen: GlobalState.timeWorkspace.open(timeWorkspace.screen)
    onRequestClose: GlobalState.timeWorkspace.close()

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
        id: calendarPopup

        anchor.item: timeWorkspace
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitHeight: 300
        implicitWidth: 600

        visible: timeWorkspace.openProgress > 0.001 || timeWorkspace.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * timeWorkspace.openProgress
                opacity: timeWorkspace.openProgress
                y: (1 - timeWorkspace.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            timeWorkspace.open()
                        } else {
                            timeWorkspace.close()
                        }
                    }
                }

                CalendarPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (timeWorkspace.openProgress - 0.25) / 0.75)

                    onRequestClose: timeWorkspace.forceClose()
                }
            }
        }
    }
}