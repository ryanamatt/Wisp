// qml/CommandCenter/SettingsSection/SettingsComponents/SettingTextField.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../Colors"
import "../../../Config"

ColumnLayout {
    id: root

    property string settingText: ""
    property string textFieldText: ""
    property var textFieldPlaceholder: ""

    signal editingFinished(string text)
    signal accepted(string text)

    readonly property int labelWidth: 160
    readonly property int controlWidth: 240
    readonly property int rowSpacing: 14
    readonly property int controlHeight: 32
    readonly property int controlRadius: 8
    readonly property int controlBorderWidth: 1

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignLeft
        spacing: root.rowSpacing
    
        Text {
            text: root.settingText
            font.pixelSize: 15
            font.family: Config.font
            font.bold: true
            color: Colors.colors.foregroundMuted

            Layout.preferredWidth: root.labelWidth
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
        }

        TextField {
            id: textField

            Layout.preferredWidth: root.controlWidth
            implicitHeight: root.controlHeight

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
}