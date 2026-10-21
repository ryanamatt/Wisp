// qml/bar/ActionWidget/ActionWidget.qml

import QtQuick
import Quickshell
import "../../Components"
import "../../IpcState"
import "../../Config"
import "../../Icons"

BarWidgetContainer {
    id: actionWidget

    required property var screen

    iconImage.source: Icons.getIcon("action")

    isOpenHere: IpcState.actionWidget.isOpenOn(actionWidget.screen)

    popupWindows: [actionPopup]

    onRequestOpen: IpcState.actionWidget.open(actionWidget.screen)
    onRequestClose: IpcState.actionWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            action.resetSelection()
            action.forceActiveFocus()
            activateFocusGrab()
        } else {
            releaseFocusGrab()
        }
    }

    // Left-aligned instead of centered: the actionPopup grows out of the corner
    // nearest the pill, and that corner squares off instead of rounding.
    WidgetPopup {
        id: actionPopup
        widget: actionWidget
        centered: false
        cornerRadius: 40
        implicitWidth: 250
        implicitHeight: 150

        ActionPopup {
            id: action
            anchors.fill: parent

            onRequestClose: actionWidget.forceClose()
        }
    }
}
