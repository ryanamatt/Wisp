// qml/Bar/Battery/BatteryWidget.qml

import QtQuick
import Quickshell
import "../../Components"
import "../../GlobalState"
import "../../Colors"

BarWidgetContainer {
    id: batteryWidget

    required property var screen

    // ----- Cycling through accessories -----
    readonly property var accessories: popup.accessories
    property int cycleIndex: 0
    readonly property var currentAccessory: accessories.length > 0
        ? accessories[cycleIndex % accessories.length]
        : null

    function advanceCycle() {
        if (batteryWidget.accessories.length < 2)
            return
        cycleAnim.start()
    }

    // Un-anchor from the container's default centerIn so the slide
    // animation below has somewhere to move to/from.
    icon.anchors.centerIn: undefined
    icon.anchors.horizontalCenter: batteryWidget.horizontalCenter
    icon.anchors.verticalCenter: batteryWidget.verticalCenter
    icon.font.pixelSize: batteryWidget.currentAccessory.charging ? implicitWidth * 0.15 : implicitWidth * 0.2
    icon.font.family: "Noto Sans Mono"

    icon.text: batteryWidget.currentAccessory
        ? (batteryWidget.currentAccessory.charging ? "\uf0e7 " : "")
          + batteryWidget.currentAccessory.icon + "  "
          + batteryWidget.currentAccessory.percent + "%"
        : "\uf109 --"

    // Rotate to the next accessory every 3-5s with a little slide + fade,
    // like a flip display rolling over to the next card.
    Timer {
        id: cycleTimer
        running: batteryWidget.accessories.length > 1
        repeat: true
        interval: 3000 + Math.floor(Math.random() * 2000)
        onTriggered: {
            batteryWidget.advanceCycle()
            interval = 3000 + Math.floor(Math.random() * 2000)
        }
    }

    SequentialAnimation {
        id: cycleAnim

        ParallelAnimation {
            NumberAnimation { target: icon; property: "opacity"; to: 0; duration: 160; easing.type: Easing.InQuad }
            NumberAnimation { target: icon; property: "anchors.verticalCenterOffset"; to: -8; duration: 160; easing.type: Easing.InQuad }
        }
        ScriptAction {
            script: {
                const count = Math.max(1, batteryWidget.accessories.length)
                batteryWidget.cycleIndex = (batteryWidget.cycleIndex + 1) % count
            }
        }
        PropertyAction { target: icon; property: "anchors.verticalCenterOffset"; value: 8 }
        ParallelAnimation {
            NumberAnimation { target: icon; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutQuad }
            NumberAnimation { target: icon; property: "anchors.verticalCenterOffset"; to: 0; duration: 180; easing.type: Easing.OutQuad }
        }
    }

    // ----- Open/close plumbing, same shape as the other widgets -----
    isOpenHere: GlobalState.batteryWidget.isOpenOn(batteryWidget.screen)

    popupWindows: [batteryPopupWindow]

    onRequestOpen: GlobalState.batteryWidget.open(batteryWidget.screen)
    onRequestClose: GlobalState.batteryWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.refreshAll()
            popup.forceActiveFocus()
            activateFocusGrab()
        } else {
            releaseFocusGrab()
        }
    }

    PopupWindow {
        id: batteryPopupWindow

        anchor.item: batteryWidget
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitWidth: 300
        implicitHeight: 260

        visible: batteryWidget.openProgress > 0.001 || batteryWidget.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * batteryWidget.openProgress
                opacity: batteryWidget.openProgress
                y: (1 - batteryWidget.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            batteryWidget.open()
                        } else {
                            batteryWidget.close()
                        }
                    }
                }

                BatteryPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (batteryWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: batteryWidget.forceClose()
                }
            }
        }
    }
}
