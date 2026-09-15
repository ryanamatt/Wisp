// qml/Bar/Clipboard/ClipboardWidget.qml

import QtQuick
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

    WidgetPopup {
        id: clipboardPopup
        widget: clipboardWidget
        implicitWidth: 320
        implicitHeight: 420

        ClipboardPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: clipboardWidget.forceClose()
        }
    }
}
