// qml/CommandCenter/SettingsSection/WeatherSubSection/GetWeatherFromIpSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "Weather IP"

    SettingToggle {
        settingText: root.name
        description: "Get Weather From Your IP"
        checked: Config.pendingGetWeatherFromIp
        modified: Config.pendingGetWeatherFromIp !== Config.getWeatherFromIp
        onToggled: (value) => Config.stageGetWeatherFromIp(value)
    }
}

