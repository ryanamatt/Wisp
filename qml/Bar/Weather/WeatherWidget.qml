// qml/Bar/Weather/WeatherWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../Colors"
import "../../Config"
import "../../Icons"

BarWidgetContainer {
    id: weatherWidget

    property int weatherCode: WeatherSingleton.weatherCode
    property int weatherTemp: WeatherSingleton.weatherTemp

    property var weatherCodeMap: [
        {
            id: "sunny",
            codes: [0, 1],
            icon: "sunny"
        },
        {
            id: "overcast",
            codes: [2],
            icon: "overcast"
        },
        {
            id: "cloudy",
            codes: [3],
            icon: "cloudy"
        },
        {
            id: "fog",
            codes: [45, 48],
            icon: "fog"
        },
        {
            id: "rain",
            codes: [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82],
            icon: "rain"
        },
        {
            id: "snow",
            codes: [71, 73, 75, 77, 85, 86],
            icon: "snow"
        },
        {
            id: "thunderstorm",
            codes: [95, 96, 99],
            icon: "thunderstorm"
        }
    ]

    function getWeatherIcon(code) {
        for (let i = 0; i < weatherCodeMap.length; i++) {
            if (weatherCodeMap[i].codes.includes(code)) {
                return weatherCodeMap[i].icon;
            }
        }
        return "E"
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 2
        Layout.alignment: Qt.AlignCenter

        Image {
            Layout.preferredWidth: weatherWidget.width * 0.3
            Layout.preferredHeight: Layout.preferredWidth
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
            source: {
                const icon = getWeatherIcon(weatherWidget.weatherCode)
                if (icon === "E") return ""

                return Icons.getIcon("weather/" + icon)
            }
        }

        Text {
            color: Colors.colors.foreground
            font.family: Config.font
            font.pixelSize: weatherWidget.width * 0.25
            text: weatherWidget.weatherTemp + "\ue33e"
        }
    }


}
