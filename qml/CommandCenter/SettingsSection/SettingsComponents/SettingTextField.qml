// qml/CommandCenter/SettingsSection/SettingsComponents/SettingTextField.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Colors"
import "../../../Config"

SettingControl {
    id: root

    property string textFieldText: ""
    property var textFieldPlaceholder: ""

    signal editingFinished(string text)
    signal accepted(string text)

    TextField {
        id: textField
        anchors.fill: parent

        text: root.textFieldText
        placeholderText: root.textFieldPlaceholder
        selectByMouse: true

        font.pixelSize: 12
        font.family: Config.font
        color: Colors.colors.foreground
        leftPadding: 10
        verticalAlignment: TextInput.AlignVCenter

        background: Rectangle {
            radius: root.controlRadius
            color: Colors.colors.surfaceAlt
            border.width: root.controlBorderWidth
            border.color: textField.activeFocus ? Colors.colors.borderActive : Colors.colors.border
        }

        onEditingFinished: root.editingFinished(text)
        onAccepted: root.accepted(text)
    }
}
