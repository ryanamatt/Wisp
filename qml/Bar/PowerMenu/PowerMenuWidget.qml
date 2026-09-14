// qml/Bar/PowerMenu/PowerMenuWidget.qml

import QtQuick
import Quickshell
import "../../Components"
import "../../IpcState"

BarWidgetContainer {
    id: powerMenu

    required property var screen

    icon.text: "\udb81\udc25"
    icon.font.pixelSize: implicitWidth * 0.6

    isOpenHere: IpcState.powerMenu.isOpenOn(powerMenu.screen)

    popupWindows: [powerMenuPopup]

    onRequestOpen: IpcState.powerMenu.open(powerMenu.screen)
    onRequestClose: IpcState.powerMenu.close()

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

    WidgetPopup {
        id: powerMenuPopup
        widget: powerMenu
        implicitWidth: 300
        implicitHeight: 75

        PowerMenuPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: powerMenu.forceClose()
        }
    }
}
