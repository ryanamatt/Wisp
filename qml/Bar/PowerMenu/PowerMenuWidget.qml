// qml/Bar/PowerMenu/PowerMenuWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../Components"
import "../../IpcState"
import "../../Colors"

BarWidgetContainer {
    id: powerMenu

    required property var screen

    iconText.text: "\udb81\udc25"
    iconText.font.pixelSize: implicitWidth * 0.6

    isOpenHere: IpcState.powerMenu.isOpenOn(powerMenu.screen)

    popupWindows: [powerMenuPopup]

    onRequestOpen: IpcState.powerMenu.open(powerMenu.screen)
    onRequestClose: IpcState.powerMenu.close()

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
        id: powerMenuPopup

        anchor.item: powerMenu
        anchor.edges: powerMenu.barAtBottom ? Edges.Top : Edges.Bottom
        anchor.gravity: (powerMenu.barAtBottom ? Edges.Top : Edges.Bottom) | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitHeight: 75
        implicitWidth: 300

        visible: powerMenu.openProgress > 0.001 || powerMenu.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: powerMenu.barAtBottom ? undefined : parent.top
                anchors.bottom: powerMenu.barAtBottom ? parent.bottom : undefined
                height: parent.height

                transformOrigin: powerMenu.barAtBottom ? Item.Bottom : Item.Top
                scale: 0.85 + 0.15 * powerMenu.openProgress
                opacity: powerMenu.openProgress
                y: powerMenu.barAtBottom
                    ? (1 - powerMenu.openProgress) * 14
                    : (1 - powerMenu.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            powerMenu.open()
                        } else {
                            powerMenu.close()
                        }
                    }
                }

                PowerMenuPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (powerMenu.openProgress - 0.25) / 0.75)

                    onRequestClose: powerMenu.forceClose()
                }
            }
        }
    }
}
