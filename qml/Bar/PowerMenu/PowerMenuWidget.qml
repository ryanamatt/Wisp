// qml/Bar/PowerMenu/PowerMenuWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../../Components"
import "../../GlobalState"
import "../../Colors"

BarWidgetContainer {
    id: powerMenu 

    required property var screen

    implicitWidth: 50

    icon.text: "\udb81\udc25"

    readonly property real fullRadius: implicitHeight / 2
    topLeftRadius: fullRadius
    topRightRadius: fullRadius
    bottomLeftRadius: fullRadius * (1 - openProgress)
    bottomRightRadius: fullRadius * (1 - openProgress)

    readonly property bool isOpenHere: GlobalState.isPowerMenuOpen
        && GlobalState.powerMenuScreen === powerMenu.screen

    property real openProgress: isOpenHere ? 1 : 0
    Behavior on openProgress {
        SpringAnimation { spring: 3.2; damping: 0.32; epsilon: 0.001 }
    }

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.resetSelection()
            popup.forceActiveFocus()
            focusGrab.active = true
        } else {
            focusGrab.active = false
        }
    }

    MouseArea {
        id: widgetHoverArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            hideTimer.stop()
            GlobalState.isPowerMenuOpen = true
            GlobalState.powerMenuScreen = powerMenu.screen
        }
        onExited: hideTimer.start()
    }

    Timer {
        id: hideTimer
        interval: 200
        onTriggered: {
            GlobalState.isPowerMenuOpen = false
            GlobalState.powerMenuScreen = null
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [powerMenuPopup]
        onCleared: {
            hideTimer.stop()
            GlobalState.isPowerMenuOpen = false
            GlobalState.powerMenuScreen = null
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
                            hideTimer.stop()
                            GlobalState.powerMenuScreen = powerMenu.screen
                            GlobalState.isPowerMenuOpen = true
                        } else {
                            hideTimer.start()
                        }
                    }
                }

                PowerMenuPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (powerMenu.openProgress - 0.25) / 0.75)

                    onRequestClose: {
                        hideTimer.stop()
                        GlobalState.isPowerMenuOpen = false
                        GlobalState.powerMenuScreen = null
                    }
                }
            }
        }
    }
}