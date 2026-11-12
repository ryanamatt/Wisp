// qml/Bar/Weather/WeatherSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int weatherCode: -1
    property int weatherTemp: 0
    property double latitude: 0
    property double longitude: 0

    Process {
        id: getLocationCoords
        command: ["bash", "-c", "curl -s https://ipwho.is | jq -r '[.latitude, .longitude] | @tsv'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const coords = text.trim().split("\t")

                if (coords.length === 2) {
                    latitude = parseFloat(coords[0])
                    longitude = parseFloat(coords[1])

                    console.log("Location:", latitude, longitude)
                    getCurrentWeather.running = true
                }
            }
        }
    }

    Process {
        id: getCurrentWeather
        command: ["bash", "-c", "curl -s \"https://api.open-meteo.com/v1/forecast?latitude=" + root.latitude + "&longitude=" + root.longitude + "1&current=temperature_2m,weather_code&temperature_unit=fahrenheit\" | jq -c '.current | {temp: (.temperature_2m | round), code: .weather_code}'"]
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
        onTriggered: getLocationCoords.running = true

        Component.onCompleted: getLocationCoords.running = true
    }

}
