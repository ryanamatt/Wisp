// qml/Bar/Clipboard/ClipboardWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../Components"
import "../../IpcState"
import "../../Colors"
import "../../Config"
import "../../Icons"

BarWidgetContainer {
    id: clipboardWidget

    required property var screen

    iconImage.source: Icons.getIcon("clipboard")
    iconImage.width: clipboardWidget.implicitWidth * 0.6

    isOpenHere: IpcState.clipboardWidget.isOpenOn(clipboardWidget.screen)

    popupWindows: [clipboardPopup]

    onRequestOpen: IpcState.clipboardWidget.open(clipboardWidget.screen)
    onRequestClose: IpcState.clipboardWidget.close()

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
        anchor.edges: clipboardWidget.barAtBottom ? Edges.Top : Edges.Bottom
        anchor.gravity: (clipboardWidget.barAtBottom ? Edges.Top : Edges.Bottom) | Edges.HCenter
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
                anchors.top: clipboardWidget.barAtBottom ? undefined : parent.top
                anchors.bottom: clipboardWidget.barAtBottom ? parent.bottom : undefined
                height: parent.height

                transformOrigin: clipboardWidget.barAtBottom ? Item.Bottom : Item.Top
                scale: 0.85 + 0.15 * clipboardWidget.openProgress
                opacity: clipboardWidget.openProgress
                y: clipboardWidget.barAtBottom
                    ? (1 - clipboardWidget.openProgress) * 14
                    : (1 - clipboardWidget.openProgress) * -14
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