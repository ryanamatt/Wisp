// qml/Bar/Weather/WeatherSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Config"

Singleton {
    id: root

    property int weatherCode: -1
    property int weatherTemp: 0
    property double latitude: 0
    property double longitude: 0

    // Picks the location source. IP wins if both are set.
    function refresh() {
        if (Config.getWeatherFromIp) {
            getIpCoords.running = true
        } else if (Config.weatherCity.trim() !== "") {
            geocodeCity.running = true
        }
    }

    // Shared handler for both location processes. Expects "lat<TAB>lon".
    function applyCoords(text) {
        const coords = text.trim().split("\t")
        if (coords.length !== 2) return

        const lat = parseFloat(coords[0])
        const lon = parseFloat(coords[1])
        if (isNaN(lat) || isNaN(lon)) return

        latitude = lat
        longitude = lon
        getCurrentWeather.running = true
    }

    // Location from the public IP address
    Process {
        id: getIpCoords
        command: ["bash", "-c", "curl -s https://ipwho.is | jq -r '[.latitude, .longitude] | @tsv'"]
        stdout: StdioCollector {
            onStreamFinished: root.applyCoords(text)
        }
    }

    // Location from a city name via Open-Meteo's geocoding API.
    // The city is passed as $1 so the shell never parses it, and
    // --data-urlencode takes care of spaces and special characters.
    Process {
        id: geocodeCity
        command: [
            "bash", "-c",
            "curl -s -G 'https://geocoding-api.open-meteo.com/v1/search' --data-urlencode \"name=$1\" --data-urlencode 'count=1' | jq -r '(.results // [])[0] // empty | [.latitude, .longitude] | @tsv'",
            "_", Config.weatherCity.trim()
        ]
        stdout: StdioCollector {
            onStreamFinished: root.applyCoords(text)
        }
    }

    Process {
        id: getCurrentWeather
        command: ["bash", "-c", "curl -s \"https://api.open-meteo.com/v1/forecast?latitude=" + root.latitude + "&longitude=" + root.longitude + "&current=temperature_2m,weather_code&temperature_unit=fahrenheit\" | jq -c '.current | {temp: (.temperature_2m | round), code: .weather_code}'"]

        stdout: SplitParser {
            onRead: data => {
                let weatherData = JSON.parse(data);
                root.weatherTemp = weatherData.temp;
                root.weatherCode = weatherData.code;
            }
        }
    }

    // Re-fetch right away when the user saves a different setting
    Connections {
        target: Config
        function onGetWeatherFromIpChanged() { root.refresh() }
        function onWeatherCityChanged() { root.refresh() }
    }

    Timer {
        id: weatherUpdateTimer
        // 5 Minutes = 5 * 60 seconds in a minute * 1000 milliseconds
        interval: 5 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh()

        Component.onCompleted: root.refresh()
    }
}
