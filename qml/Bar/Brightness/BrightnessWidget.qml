// qml/Bar/Brightness/BrightnessWidget.qml

import QtQuick
import Quickshell
import "../../Components"
import "../../GlobalState"
import "../../Colors"

BarWidgetContainer {
    id: brightnessWidget

    required property var screen

    implicitWidth: 75

    icon.font.pixelSize: popup.hasBacklight ? popup.nightlightEnabled ? 15 : 20 : 30
    icon.font.family: "Noto Sans Mono"
    icon.text: {
        const nightGlyph = popup.nightlightEnabled ? "\uf186 " : ""

        if (popup.hasBacklight)
            return nightGlyph + "\uf185 " + popup.brightnessPercent + "%"

        // Desktop monitors with no controllable backlight: only the
        // night-light state is meaningful here.
        return popup.nightlightEnabled ? "\uf186 On" : "\uf186"
    }

    isOpenHere: GlobalState.brightnessWidget.isOpenOn(brightnessWidget.screen)

    popupWindows: [brightnessPopupWindow]

    onRequestOpen: GlobalState.brightnessWidget.open(brightnessWidget.screen)
    onRequestClose: GlobalState.brightnessWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.refreshBrightness()
            popup.forceActiveFocus()
            activateFocusGrab()
        } else {
            releaseFocusGrab()
        }
    }

    PopupWindow {
        id: brightnessPopupWindow

        anchor.item: brightnessWidget
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitWidth: 300
        implicitHeight: 190

        visible: brightnessWidget.openProgress > 0.001 || brightnessWidget.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * brightnessWidget.openProgress
                opacity: brightnessWidget.openProgress
                y: (1 - brightnessWidget.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            brightnessWidget.open()
                        } else {
                            brightnessWidget.close()
                        }
                    }
                }

                BrightnessPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (brightnessWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: brightnessWidget.forceClose()
                }
            }
        }
    }
}
