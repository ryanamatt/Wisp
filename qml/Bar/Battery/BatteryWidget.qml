// qml/Bar/Battery/BatteryWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Components"
import "../../IpcState"
import "../../Colors"
import "../../Config"
import "../../Icons"

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

    iconText.visible: false
    iconImage.visible: false

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 6
        Layout.alignment: Qt.AlignCenter

        Image {
            visible: batteryWidget.currentAccessory && batteryWidget.currentAccessory.charging
            Layout.preferredWidth: batteryWidget.width * 0.2
            Layout.preferredHeight: batteryWidget.width * 0.2
            fillMode: Image.PreserveAspectFit
            source: Icons.getIcon("electricBolt")
        }

        Image {
            Layout.preferredWidth: (batteryWidget.currentAccessory && batteryWidget.currentAccessory.charging) 
                ? batteryWidget.width * 0.2
                : batteryWidget.width * 0.25
            Layout.preferredHeight: batteryWidget.implicitWidth
            fillMode: Image.PreserveAspectFit
            source: batteryWidget.currentAccessory
                ? Icons.getIcon(batteryWidget.currentAccessory.icon)
                : Icons.getIcon("laptop")
        }

        Text {
            color: Colors.colors.foreground
            font.family: Config.font
            font.pixelSize: (batteryWidget.currentAccessory && batteryWidget.currentAccessory.charging) 
                ? batteryWidget.width * 0.15
                : batteryWidget.width * 0.2
            text: batteryWidget.currentAccessory
                ? batteryWidget.currentAccessory.percent + "%"
                : "--%"
        }
    }

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
            NumberAnimation { target: iconImage; property: "opacity"; to: 0; duration: 160; easing.type: Easing.InQuad }
            NumberAnimation { target: iconImage; property: "anchors.verticalCenterOffset"; to: -8; duration: 160; easing.type: Easing.InQuad }
        }
        ScriptAction {
            script: {
                const count = Math.max(1, batteryWidget.accessories.length)
                batteryWidget.cycleIndex = (batteryWidget.cycleIndex + 1) % count
            }
        }
        PropertyAction { target: iconImage; property: "anchors.verticalCenterOffset"; value: 8 }
        ParallelAnimation {
            NumberAnimation { target: iconImage; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutQuad }
            NumberAnimation { target: iconImage; property: "anchors.verticalCenterOffset"; to: 0; duration: 180; easing.type: Easing.OutQuad }
        }
    }

    // ----- Open/close plumbing, same shape as the other widgets -----
    isOpenHere: IpcState.batteryWidget.isOpenOn(batteryWidget.screen)

    popupWindows: [batteryPopupWindow]

    onRequestOpen: IpcState.batteryWidget.open(batteryWidget.screen)
    onRequestClose: IpcState.batteryWidget.close()

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
        anchor.edges: batteryWidget.barAtBottom ? Edges.Top : Edges.Bottom
        anchor.gravity: (batteryWidget.barAtBottom ? Edges.Top : Edges.Bottom) | Edges.HCenter
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
                anchors.top: batteryWidget.barAtBottom ? undefined : parent.top
                anchors.bottom: batteryWidget.barAtBottom ? parent.bottom : undefined
                height: parent.height

                transformOrigin: batteryWidget.barAtBottom ? Item.Bottom : Item.Top
                scale: 0.85 + 0.15 * batteryWidget.openProgress
                opacity: batteryWidget.openProgress
                y: batteryWidget.barAtBottom
                    ? (1 - batteryWidget.openProgress) * 14
                    : (1 - batteryWidget.openProgress) * -14
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
