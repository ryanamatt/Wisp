// qml/OSD/OSDBrightness.qml

import "../Icons"
import Wisp.Brightness

OSDBase {
    whenVisible: OSDSingleton.isBrightnessOSDVisible
    icon: Icons.getIcon("brightness")
    barValue: Brightness.brightnessPercent
    valueText: Brightness.brightnessPercent + "%"
}
