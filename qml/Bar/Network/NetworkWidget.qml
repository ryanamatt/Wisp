// qml/Bar/Network/NetworkWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../GlobalState"
import "../../Colors"

BarWidgetContainer {
    id: networkWidget

    required property var screen

    // Shared status now lives in NetworkSingleton, polled centrally instead
    // of once per monitor, so the bar icon on every screen stays accurate
    // even while the popup is closed.
    readonly property string connectionType: NetworkSingleton.connectionType

    icon.text: connectionType === "ethernet" ? "\udb80\ude01" : "\uf1eb"
    icon.color: connectionType === "none" ? Colors.colors.foregroundMuted : Colors.colors.foreground
    icon.font.pixelSize: implicitWidth * 0.6

    isOpenHere: GlobalState.networkWidget.isOpenOn(networkWidget.screen)

    popupWindows: [networkPopupWindow]

    onRequestOpen: GlobalState.networkWidget.open(networkWidget.screen)
    onRequestClose: GlobalState.networkWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.resetSelection()
            popup.forceActiveFocus()
            popup.refreshAll()
            activateFocusGrab()
        } else {
            popup.closePopup()
            releaseFocusGrab()
        }
    }

    PopupWindow {
        id: networkPopupWindow

        anchor.item: networkWidget
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitHeight: 300
        implicitWidth: 300

        visible: networkWidget.openProgress > 0.001 || networkWidget.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * networkWidget.openProgress
                opacity: networkWidget.openProgress
                y: (1 - networkWidget.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            networkWidget.open()
                        } else {
                            networkWidget.close()
                        }
                    }
                }

                NetworkPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (networkWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: networkWidget.forceClose()
                }
            }
        }
    }
}
