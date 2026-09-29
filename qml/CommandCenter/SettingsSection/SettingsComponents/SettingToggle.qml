// qml/CommandCenter/SettingsSection/SettingsComponents/SettingToggle.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Colors"
import "../../../Config"

ColumnLayout {
    id: root
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true

    spacing: 6

    property string settingText: ""
    property string description: ""
    property bool checked: false

    // Shared metrics (kept in step with SettingComboBox so rows line up)
    readonly property int labelWidth: 160
    readonly property int rowSpacing: 14
    readonly property int controlHeight: 32
    readonly property int trackWidth: 46
    readonly property int trackHeight: 24
    readonly property int knobMargin: 3

    signal toggled(bool value)

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignLeft
        Layout.preferredHeight: root.controlHeight
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

        Rectangle {
            id: track

            Layout.preferredWidth: root.trackWidth
            Layout.preferredHeight: root.trackHeight
            Layout.alignment: Qt.AlignVCenter

            radius: height / 2
            color: root.checked ? Colors.colors.accent : Colors.colors.surfaceAlt
            border.width: 1
            border.color: (trackArea.containsMouse || root.checked) ? Colors.colors.borderActive : Colors.colors.border

            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                id: knob
                width: track.height - root.knobMargin * 2
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? track.width - width - root.knobMargin : root.knobMargin
                color: root.checked ? Colors.colors.background : Colors.colors.foregroundMuted

                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: trackArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled(!root.checked)
            }
        }
    }

    Text {
        visible: root.description.length > 0
        text: root.description
        wrapMode: Text.WordWrap
        font.pixelSize: 11
        font.family: Config.font
        color: Colors.colors.foregroundMuted

        Layout.fillWidth: true
        Layout.leftMargin: root.labelWidth + root.rowSpacing
    }
}
