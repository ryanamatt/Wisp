// qml/Bar/Brightness/BrightnessWidget.qml

import QtQuick
import Quickshell
import "../../Components"
import "../../IpcState"

BarWidgetContainer {
    id: brightnessWidget

    required property var screen

    icon.font.pixelSize: BrightnessSingleton.hasBacklight ? BrightnessSingleton.nightlightEnabled ? 12 : 15 : 30
    icon.text: {
        const nightGlyph = BrightnessSingleton.nightlightEnabled ? "\uf186 " : ""

        if (BrightnessSingleton.hasBacklight)
            return nightGlyph + "\uf185 " + BrightnessSingleton.brightnessPercent + "%"

        // Desktop monitors with no controllable backlight: only the
        // night-light state is meaningful here.
        return BrightnessSingleton.nightlightEnabled ? "\udb86\udc29" : "\uf186"
    }

    isOpenHere: IpcState.brightnessWidget.isOpenOn(brightnessWidget.screen)

    popupWindows: [brightnessPopupWindow]

    onRequestOpen: IpcState.brightnessWidget.open(brightnessWidget.screen)
    onRequestClose: IpcState.brightnessWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            BrightnessSingleton.refreshBrightness()
            popup.forceActiveFocus()
            activateFocusGrab()
        } else {
            releaseFocusGrab()
        }
    }

    WidgetPopup {
        id: brightnessPopupWindow
        widget: brightnessWidget
        implicitWidth: 300
        implicitHeight: 190

        BrightnessPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: brightnessWidget.forceClose()
        }
    }
}
