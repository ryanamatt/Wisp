// qml/CommandCenter/SettingsSection/WeatherSubSection/WeatherSubSection.qml

import "../SettingsComponents/"

SettingsSubSection {
    name: "Weather Settings"

    GetWeatherFromIpSetting {}
    WeatherCitySetting {}
}
