// qml/Bar/Brightness/BrightnessWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Components"
import "../../IpcState"
import "../../Colors"
import "../../Config"
import "../../Icons"

BarWidgetContainer {
    id: brightnessWidget

    required property var screen

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 2
        Layout.alignment: Qt.AlignCenter

        Image {
            visible: BrightnessSingleton.nightlightEnabled
            Layout.preferredWidth: BrightnessSingleton.hasBacklight 
                ? brightnessWidget.width * 0.2
                : brightnessWidget.width * 0.3
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            source: Icons.getIcon("moon")
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
        }

        Image {
            visible: BrightnessSingleton.hasBacklight
            Layout.preferredWidth: BrightnessSingleton.nightlightEnabled 
                ? brightnessWidget.width * 0.2
                : brightnessWidget.width * 0.25
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            source: Icons.getIcon("brightness")
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
        }

        Image {
            visible: !BrightnessSingleton.hasBacklight && !BrightnessSingleton.nightlightEnabled
            Layout.preferredWidth: brightnessWidget.width * 0.3
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            source: Icons.getIcon("moonOff")
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
        }

        Text {
            visible: BrightnessSingleton.hasBacklight
            color: Colors.colors.foreground
            font.family: Config.font
            font.pixelSize: Math.round(BrightnessSingleton.nightlightEnabled
                ? brightnessWidget.width * 0.15
                : brightnessWidget.width * 0.2)
            text: BrightnessSingleton.brightnessPercent
            ? BrightnessSingleton.brightnessPercent + "%"
            : "--%"
        }

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

    PopupWindow {
        id: brightnessPopupWindow

        anchor.item: brightnessWidget
        anchor.edges: brightnessWidget.barAtBottom ? Edges.Top : Edges.Bottom
        anchor.gravity: (brightnessWidget.barAtBottom ? Edges.Top : Edges.Bottom) | Edges.HCenter
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
                anchors.top: brightnessWidget.barAtBottom ? undefined : parent.top
                anchors.bottom: brightnessWidget.barAtBottom ? parent.bottom : undefined
                height: parent.height

                transformOrigin: brightnessWidget.barAtBottom ? Item.Bottom : Item.Top
                scale: 0.85 + 0.15 * brightnessWidget.openProgress
                opacity: brightnessWidget.openProgress
                y: brightnessWidget.barAtBottom
                    ? (1 - brightnessWidget.openProgress) * 14
                    : (1 - brightnessWidget.openProgress) * -14
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
