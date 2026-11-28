// qml/Bar/Weather/WeatherWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../IpcState"
import "../../Colors"
import "../../Config"
import "../../Icons"

BarWidgetContainer {
    id: weatherWidget

    required property var screen

    // Shared state lives in WeatherSingleton, so every monitor stays in sync.
    property int weatherCode: WeatherSingleton.weatherCode
    property int weatherTemp: WeatherSingleton.weatherTemp
    property bool weatherIsDay: WeatherSingleton.weatherIsDay

    isOpenHere: IpcState.weatherWidget.isOpenOn(weatherWidget.screen)

    popupWindows: [weatherPopupWindow]

    onRequestOpen: IpcState.weatherWidget.open(weatherWidget.screen)
    onRequestClose: IpcState.weatherWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.resetScroll()
            popup.forceActiveFocus()
            popup.refreshAll()
            activateFocusGrab()
        } else {
            popup.closePopup()
            releaseFocusGrab()
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 2
        Layout.alignment: Qt.AlignCenter

        // If getWeatherFromIp

        Image {
            visible: Config.getWeatherFromIp || Config.weatherCity !== ""
            Layout.preferredWidth: weatherWidget.width * 0.3
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
            source: {
                const icon = WeatherSingleton.getWeatherIcon(weatherWidget.weatherCode, weatherWidget.weatherIsDay)
                if (icon === "") return ""

                return Icons.getIcon("weather/" + icon)
            }
        }

        Text {
            visible: Config.getWeatherFromIp || Config.weatherCity !== ""
            color: Colors.colors.foreground
            font.family: Config.font
            font.pixelSize: weatherWidget.width * 0.25
            text: weatherWidget.weatherTemp + "\ue33e"
        }

        // If not getWeatherFromIp
        Image {
            visible: !Config.getWeatherFromIp && !Config.weatherCity
            Layout.preferredWidth: weatherWidget.width * 0.4
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
            source: Icons.getIcon("weather/cloudLock")
        }

    }

    // Sized from the monitor so it scales between desktop and laptop.
    // Width is 340 / 1900 of the screen width (same basis as Bar.qml), with
    // a floor so the cards stay readable on small screens. Height is a fixed
    // ratio of the width, so the proportions never change.
    WidgetPopup {
        id: weatherPopupWindow
        widget: weatherWidget
        implicitWidth: Math.max(300, Math.round(weatherWidget.screen.width * (340 / 1900)))
        implicitHeight: Math.round(implicitWidth * 0.6)

        WeatherPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: weatherWidget.forceClose()
        }
    }
}
