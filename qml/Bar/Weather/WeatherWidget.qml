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
            codes: [113],
            icon: "sunny"
        },
        {
            id: "overcast",
            codes: [116],
            icon: "overcast"
        },
        { 
            id: "cloudy", 
            codes: [119, 122],
            icon: "cloudy"
        },
        {
            id: "fog", 
            codes: [143, 248, 260, 389, 392, 395],
            icon: "fog"
        },
        { 
            id: "rain",
            codes: [176, 185, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 317, 320, 350, 353, 356, 359, 362, 365],
            icon: "rain"
        },
        { 
            id: "snow", 
            codes: [179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371, 374, 377],
            icon: "snow"
        }, 
        { 
            id: "thunderstorm",
            codes: [200, 386, 391, 394, 395],
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
