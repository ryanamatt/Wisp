// qml/CommandCenter/SettingsSection/WeatherSubSection/WeatherCitySetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "Weather City"

    SettingTextField {
        settingText: root.name
        textFieldText: Config.pendingWeatherCity
        textFieldPlaceholder: "Your City"
        modified: Config.pendingWeatherCity !== Config.weatherCity

        // The one preview that should render in the staged font
        previewText: "City is " + Config.pendingWeatherCity + ". (not applied if IP set)"

        onEditingFinished: (text) => Config.stageWeatherCity(text)
        onAccepted: (text) => Config.stageWeatherCity(text)
    }
}

