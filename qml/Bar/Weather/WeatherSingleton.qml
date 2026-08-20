// qml/Bar/Weather/WeatherSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int weatherCode: -1
    property int weatherTemp: 0

    Process {
        id: getCurrentWeather
        command: ["bash", "-c", "curl -s \"wttr.in/?format=j1&u\" | jq -c '.current_condition[0] | {temp: (.temp_F | tonumber), code: (.weatherCode | tonumber)}'"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                let weatherData = JSON.parse(data);
                root.weatherTemp = weatherData.temp;
                root.weatherCode = weatherData.code;
            }
        }

    }

    Timer {
        id: weatherUpdateTimer
        // 5 Minutes = 5 * 60 seconds in a minute * 1000 milliseconds
        interval: 5 * 60 * 1000 
        repeat: true
        running: true
        onTriggered: {
            getCurrentWeather.running = true
        }

        Component.onCompleted: getCurrentWeather.running = true
    }

}