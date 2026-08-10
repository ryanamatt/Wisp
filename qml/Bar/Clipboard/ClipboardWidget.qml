// qml/Bar/Clipboard/ClipboardWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../Components"
import "../../GlobalState"
import "../../Colors"

BarWidgetContainer {
    id: clipboardWidget

    required property var screen

    implicitWidth: 50

    icon.text: "\udb82\ude38"

    isOpenHere: GlobalState.clipboardWidget.isOpenOn(clipboardWidget.screen)

    popupWindows: [clipboardPopup]

    onRequestOpen: GlobalState.clipboardWidget.open(clipboardWidget.screen)
    onRequestClose: GlobalState.clipboardWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.resetSelection()
            popup.forceActiveFocus()
            popup.refreshClipboard()
            activateFocusGrab()
        } else {
            popup.closePopup()
            releaseFocusGrab()
        }
    }

    PopupWindow {
        id: clipboardPopup

        anchor.item: clipboardWidget
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitHeight: 420
        implicitWidth: 320

        visible: clipboardWidget.openProgress > 0.001 || clipboardWidget.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * clipboardWidget.openProgress
                opacity: clipboardWidget.openProgress
                y: (1 - clipboardWidget.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            clipboardWidget.open()
                        } else {
                            clipboardWidget.close()
                        }
                    }
                }

                ClipboardPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (clipboardWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: clipboardWidget.forceClose()
                }
            }
        }
    }
}