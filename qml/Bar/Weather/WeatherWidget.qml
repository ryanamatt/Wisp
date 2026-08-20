// qml/Bar/Weather/WeatherWidget.qml

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../Colors"

BarWidgetContainer {
    id: weatherWidget 

    property int weatherCode: WeatherSingleton.weatherCode
    property int weatherTemp: WeatherSingleton.weatherTemp

    // Process {
    //     id: getCurrentWeather
    //     command: ["bash", "-c", "curl -s \"wttr.in/?format=j1&u\" | jq -c '.current_condition[0] | {temp: (.temp_F | tonumber), code: (.weatherCode | tonumber)}'"]
    //     // running: true

    //     stdout: SplitParser {
    //         onRead: data => {
    //             let weatherData = JSON.parse(data);
    //             weatherWidget.weatherTemp = weatherData.temp;
    //             weatherWidget.weatherCode = weatherData.code;
    //         }
    //     }

    // }

    // Timer {
    //     id: weatherUpdateTimer
    //     // 5 Minutes = 5 * 60 seconds in a minute * 1000 milliseconds
    //     interval: 5 * 60 * 1000 
    //     repeat: true
    //     onTriggered: {
    //         getCurrentWeather.running = true
    //     }
    // }

    property var weatherCodeMap: [
        { 
            id: "sunny", 
            codes: [113],
            icon: "\ue30d"
        },
        {
            id: "overcast",
            codes: [116],
            icon: "\ue30c"
        },
        { 
            id: "cloudy", 
            codes: [119, 122],
            icon: "\ue302"
        },
        {
            id: "fog", 
            codes: [143, 248, 260, 389, 392, 395],
            icon: "\ue313"
        },
        { 
            id: "rain",
            codes: [176, 185, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 317, 320, 350, 353, 356, 359, 362, 365],
            icon: "\ue318"
        },
        { 
            id: "snow", 
            codes: [179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371, 374, 377],
            icon: "\udb83\udf36"
        }, 
        { 
            id: "thunderstorm",
            codes: [200, 386, 391, 394, 395],
            icon: "\ue31d"
        } 
    ]

    function getWeatherIcon(code) {
        for (let i = 0; i < weatherCodeMap.length; i++) {
            if (weatherCodeMap[i].codes.includes(code)) {
                return weatherCodeMap[i].icon;
            }
        }
        return "E";
    }

    // Component.onCompleted: {
    //     getCurrentWeather.running = true
    //     weatherUpdateTimer.start()
    // }

    icon.text: getWeatherIcon(weatherCode) + " " + weatherWidget.weatherTemp + "\ue33e"
    icon.font.pixelSize: implicitWidth * 0.3
}
