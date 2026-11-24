// qml/Bar/Weather/WeatherSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Config"

Singleton {
    id: root

    // ----- Current conditions (used by the bar widget and popup header) -----
    property int weatherCode: -1
    property int weatherTemp: 0
    property bool weatherIsDay: true
    property int highTemp: 0
    property int lowTemp: 0

    // ----- Location -----
    property double latitude: 0
    property double longitude: 0
    // Display name of the resolved location. Empty if the source gave none.
    property string locationName: ""

    // ----- Hourly forecast -----
    // Up to 24 entries starting at the current hour:
    // { hour: 0-23, temp: int (F), code: int, isDay: bool, precip: int (%) }
    property var hourly: []

    // True when the last fetch failed to produce usable data. Old data is
    // kept on failure so the popup does not go blank on a network blip.
    property bool fetchFailed: false
    // Date.now() of the last successful fetch, 0 if none yet.
    property double lastUpdated: 0

    // ----- Icons and descriptions -----
    // WMO weather codes grouped by icon. nightIcon, if present, is used
    // instead of icon when it is not daytime.
    property var weatherCodeMap: [
        {
            id: "sunny",
            codes: [0, 1],
            icon: "sunny",
            nightIcon: "clearNight"
        },
        {
            id: "overcast",
            codes: [2],
            icon: "overcast",
            nightIcon: "partlyCloudyNight"
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

    // Returns the icon name (relative to weather/) or "" if the code is unknown.
    function getWeatherIcon(code, isDay) {
        for (let i = 0; i < weatherCodeMap.length; i++) {
            const entry = weatherCodeMap[i]
            if (entry.codes.includes(code)) {
                if (isDay === false && entry.nightIcon)
                    return entry.nightIcon
                return entry.icon
            }
        }
        return ""
    }

    function describe(code) {
        if (code === 0) return "Clear sky"
        if (code === 1) return "Mostly clear"
        if (code === 2) return "Partly cloudy"
        if (code === 3) return "Overcast"
        if (code === 45 || code === 48) return "Fog"
        if (code >= 51 && code <= 57) return "Drizzle"
        if (code >= 61 && code <= 67) return "Rain"
        if (code >= 71 && code <= 77) return "Snow"
        if (code >= 80 && code <= 82) return "Rain showers"
        if (code === 85 || code === 86) return "Snow showers"
        if (code >= 95 && code <= 99) return "Thunderstorm"
        return ""
    }

    // Formats an hour (0-23) following the user's time format setting.
    // Any "a" or "A" in a Qt format string means AM/PM is in use.
    // Reading Config.timeFormat here means bindings that call this update
    // when the setting changes.
    function formatHour(hour) {
        if (/a/i.test(Config.timeFormat))
            return ((hour % 12) || 12) + " " + (hour < 12 ? "AM" : "PM")
        return (hour < 10 ? "0" : "") + hour + ":00"
    }

    // ----- Fetching -----

    // Picks the location source. IP wins if both are set.
    function refresh() {
        if (Config.getWeatherFromIp) {
            getIpCoords.running = true
        } else if (Config.weatherCity.trim() !== "") {
            geocodeCity.running = true
        }
    }

    // Used when the popup opens. Skips the network call if data is fresh.
    function refreshIfStale() {
        if (Date.now() - lastUpdated > 60 * 1000)
            refresh()
    }

    // Shared handler for both location processes.
    // Expects "lat<TAB>lon" or "lat<TAB>lon<TAB>name".
    function applyCoords(text) {
        const parts = text.trim().split("\t")
        if (parts.length < 2) return

        const lat = parseFloat(parts[0])
        const lon = parseFloat(parts[1])
        if (isNaN(lat) || isNaN(lon)) return

        latitude = lat
        longitude = lon
        locationName = parts.length >= 3 ? parts[2].trim() : ""
        getWeather.running = true
    }

    function applyWeather(text) {
        const raw = text.trim()
        if (raw.length === 0) {
            fetchFailed = true
            return
        }

        try {
            const d = JSON.parse(raw)

            // Hourly data starts at midnight today. Find the entry for the
            // current hour (ISO strings compare correctly as text) and
            // keep the next 24 hours from there.
            const nowHour = d.now.slice(0, 13) + ":00"
            let start = d.hourly.findIndex(h => h.time >= nowHour)
            if (start < 0) start = 0

            const slice = d.hourly.slice(start, start + 24).map(h => ({
                hour: parseInt(h.time.slice(11, 13), 10),
                temp: h.temp,
                code: h.code,
                isDay: h.isDay === 1,
                precip: h.precip === null ? 0 : h.precip
            }))

            weatherTemp = d.temp
            weatherCode = d.code
            weatherIsDay = d.isDay === 1
            highTemp = d.high
            lowTemp = d.low
            hourly = slice
            fetchFailed = false
            lastUpdated = Date.now()
        } catch (e) {
            console.warn("WeatherSingleton: failed to parse weather data:", e)
            fetchFailed = true
        }
    }

    // Location from the public IP address
    Process {
        id: getIpCoords
        command: ["bash", "-c", "curl -s https://ipwho.is | jq -r '[.latitude, .longitude, .city] | @tsv'"]
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
            "curl -s -G 'https://geocoding-api.open-meteo.com/v1/search' --data-urlencode \"name=$1\" --data-urlencode 'count=1' | jq -r '(.results // [])[0] // empty | [.latitude, .longitude, .name] | @tsv'",
            "_", Config.weatherCity.trim()
        ]
        stdout: StdioCollector {
            onStreamFinished: root.applyCoords(text)
        }
    }

    // One request for current conditions, the hourly forecast and today's
    // high/low. timezone=auto makes every time string local to the
    // location. forecast_days=2 guarantees 24 hours ahead even late in
    // the evening. The URL is passed as $1 and jq flattens the response
    // into one JSON line.
    Process {
        id: getWeather
        command: [
            "bash", "-c",
            "curl -sf --max-time 15 \"$1\" | jq -c '{temp: (.current.temperature_2m | round), code: .current.weather_code, isDay: .current.is_day, now: .current.time, high: (.daily.temperature_2m_max[0] | round), low: (.daily.temperature_2m_min[0] | round), hourly: [range(0; (.hourly.time | length)) as $i | {time: .hourly.time[$i], temp: (.hourly.temperature_2m[$i] | round), code: .hourly.weather_code[$i], isDay: .hourly.is_day[$i], precip: .hourly.precipitation_probability[$i]}]}'",
            "_",
            "https://api.open-meteo.com/v1/forecast?latitude=" + root.latitude
                + "&longitude=" + root.longitude
                + "&current=temperature_2m,weather_code,is_day"
                + "&hourly=temperature_2m,weather_code,is_day,precipitation_probability"
                + "&daily=temperature_2m_max,temperature_2m_min"
                + "&temperature_unit=fahrenheit&timezone=auto&forecast_days=2"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.applyWeather(text)
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
