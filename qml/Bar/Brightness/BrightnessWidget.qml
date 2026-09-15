// qml/Bar/Brightness/BrightnessWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Components"
import "../../IpcState"
import "../../Colors"
import "../../Config"
import "../../Icons"
import Wisp.Brightness

BarWidgetContainer {
    id: brightnessWidget

    required property var screen

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 2
        Layout.alignment: Qt.AlignCenter

        Image {
            visible: Brightness.nightlightEnabled
            Layout.preferredWidth: Brightness.hasBacklight 
                ? brightnessWidget.width * 0.2
                : brightnessWidget.width * 0.3
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            source: Icons.getIcon("moon")
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
        }

        Image {
            visible: Brightness.hasBacklight
            Layout.preferredWidth: Brightness.nightlightEnabled 
                ? brightnessWidget.width * 0.2
                : brightnessWidget.width * 0.25
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            source: Icons.getIcon("brightness")
        }

        Image {
            visible: !Brightness.hasBacklight && !Brightness.nightlightEnabled
            Layout.preferredWidth: brightnessWidget.width * 0.3
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            source: Icons.getIcon("moonOff")
        }

        Text {
            visible: Brightness.hasBacklight
            color: Colors.colors.foreground
            font.family: Config.font
            font.pixelSize: Math.round(Brightness.nightlightEnabled
                ? brightnessWidget.width * 0.15
                : brightnessWidget.width * 0.2)
            text: Brightness.brightnessPercent
            ? Brightness.brightnessPercent + "%"
            : "--%"
        }

    }

    isOpenHere: IpcState.brightnessWidget.isOpenOn(brightnessWidget.screen)

    popupWindows: [brightnessPopupWindow]

    onRequestOpen: IpcState.brightnessWidget.open(brightnessWidget.screen)
    onRequestClose: IpcState.brightnessWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            Brightness.refreshBrightness()
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
