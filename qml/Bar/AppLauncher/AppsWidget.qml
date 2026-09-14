// qml/bar/AppLauncher/AppsWidget.qml

import QtQuick
import Quickshell
import "../../Components"
import "../../IpcState"

BarWidgetContainer {
    id: appsWidget

    required property var screen

    icon.text: "\uf40e"

    isOpenHere: IpcState.appLauncher.isOpenOn(appsWidget.screen)

    popupWindows: [launcherPopup]

    onRequestOpen: IpcState.appLauncher.open(appsWidget.screen)
    onRequestClose: IpcState.appLauncher.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            launcher.resetSelection()
            launcher.forceActiveFocus()
            activateFocusGrab()
        } else {
            releaseFocusGrab()
        }
    }

    // Left-aligned instead of centered: the popup grows out of the corner
    // nearest the pill, and that corner squares off instead of rounding.
    WidgetPopup {
        id: launcherPopup
        widget: appsWidget
        centered: false
        cornerRadius: 40
        implicitWidth: 400
        implicitHeight: 300

        AppLauncher {
            id: launcher
            anchors.fill: parent

            onRequestClose: appsWidget.forceClose()
        }
    }
}
