// qml/CommandCenter/SettingsSection/SettingsComponents/SettingControl.qml

import QtQuick
import QtQuick.Layouts
import "../../../Colors"
import "../../../Config"

// Shared layout for a single setting row: [label] [control] [unsaved dot],
// with an optional preview line underneath the control.
// Whatever child you declare inside goes into the control slot.
ColumnLayout {
    id: root

    property string settingText: ""
    property bool modified: false

    // Small line shown under the control. Hidden while empty.
    property string previewText: ""
    property string previewFontFamily: Config.font

    // Shared metrics (single source of truth for all row-style settings)
    readonly property int labelWidth: 160
    readonly property int controlWidth: 220
    readonly property int rowSpacing: 14
    readonly property int controlHeight: 32
    readonly property int controlRadius: 8
    readonly property int controlBorderWidth: 1

    default property alias control: controlSlot.data

    Layout.fillWidth: true
    spacing: 6

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

        Item {
            id: controlSlot
            Layout.preferredWidth: root.controlWidth
            Layout.preferredHeight: root.controlHeight
            Layout.alignment: Qt.AlignVCenter
        }

        UnsavedIndicator {
            active: root.modified
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Text {
        visible: root.previewText !== ""

        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: root.labelWidth + root.rowSpacing
        Layout.preferredWidth: root.controlWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAnywhere

        font.pixelSize: 11
        font.family: root.previewFontFamily
        color: Colors.colors.accentAlt

        text: root.previewText
    }
}
