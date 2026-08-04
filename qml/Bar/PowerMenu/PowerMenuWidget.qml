// qml/Bar/PowerMenu/PowerMenuWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../Components"
import "../../GlobalState"
import "../../Colors"

BarWidgetContainer {
    id: powerMenu

    required property var screen

    implicitWidth: 50

    icon.text: "\udb81\udc25"

    isOpenHere: GlobalState.isPowerMenuOpen
        && GlobalState.powerMenuScreen === powerMenu.screen

    popupWindows: [powerMenuPopup]

    onRequestOpen: {
        GlobalState.powerMenuScreen = powerMenu.screen
        GlobalState.isPowerMenuOpen = true
    }
    onRequestClose: {
        GlobalState.isPowerMenuOpen = false
        GlobalState.powerMenuScreen = null
    }

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
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
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
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * powerMenu.openProgress
                opacity: powerMenu.openProgress
                y: (1 - powerMenu.openProgress) * -14
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
