// qml/Bar/Network/NetworkWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../IpcState"
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

    isOpenHere: IpcState.networkWidget.isOpenOn(networkWidget.screen)

    popupWindows: [networkPopupWindow]

    onRequestOpen: IpcState.networkWidget.open(networkWidget.screen)
    onRequestClose: IpcState.networkWidget.close()

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

    WidgetPopup {
        id: networkPopupWindow
        widget: networkWidget
        implicitWidth: 300
        implicitHeight: 300

        NetworkPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: networkWidget.forceClose()
        }
    }
}
