// qml/Bar/ThemeSwitcher/ThemeSwitcherWidget.qml

import QtQuick
import Quickshell
import Quickshell.Io
import "../../GlobalState"
import "../../Components"
import "../../Colors"

BarWidgetContainer {
    id: switcherWidget 

    required property var screen

    implicitWidth: 50

    icon.text: "\ueb5c"

    isOpenHere: GlobalState.switcherWidget.isOpenOn(switcherWidget.screen)

    popupWindows: [switcherPopup]

    onRequestOpen: GlobalState.switcherWidget.open(switcherWidget.screen)
    onRequestClose: GlobalState.switcherWidget.close()

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
        id: switcherPopup

        anchor.item: switcherWidget
        anchor.edges: Edges.Bottom

        color: "transparent"

        implicitHeight: 400
        implicitWidth: 400

        visible: switcherWidget.openProgress > 0.001 || switcherWidget.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * switcherWidget.openProgress
                opacity: switcherWidget.openProgress
                y: (1 - switcherWidget.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            switcherWidget.open()
                        } else {
                            switcherWidget.close()
                        }
                    }
                }

                SwitcherPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (switcherWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: switcherWidget.forceClose()
                }
            }
        }
    }
}
