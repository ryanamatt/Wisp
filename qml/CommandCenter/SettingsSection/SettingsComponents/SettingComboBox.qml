// qml/CommandCenter/SettingsSection/SettingsComponents/SettingComboBox.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../Colors"
import "../../../Config"
import "../../../Icons"

ColumnLayout {
    id: root
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true

    spacing: 6

    property string settingText: ""
    property string pendingValue: ""
    property var presets: []

    // Shared metrics
    readonly property int labelWidth: 160
    readonly property int controlWidth: 240
    readonly property int rowSpacing: 14
    readonly property int controlHeight: 32
    readonly property int controlRadius: 8
    readonly property int controlBorderWidth: 1

    signal activated(var value)


    function indexForFormat(format) {
        for (let i = 0; i < presets.length; i++) {
            if (presets[i].value === format) return i
        }
        return -1
    }

    readonly property var fullModel: {
        const idx = indexForFormat(pendingValue)
        if (idx !== -1) return presets
        return presets.concat([{ label: "Custom", value: pendingValue }])
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignLeft
        spacing: root.rowSpacing

        Text {
            id: settingLabel
            text: settingText
            font.pixelSize: 15
            font.family: Config.font
            font.bold: true
            color: Colors.colors.foregroundMuted

            Layout.preferredWidth: root.labelWidth
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
        }

        ComboBox {
            id: comboBox

            Layout.preferredWidth: root.controlWidth
            implicitHeight: root.controlHeight

            model: root.fullModel
            textRole: "label"

            currentIndex: {
                const idx = root.indexForFormat(pendingValue)
                return idx !== -1 ? idx : root.fullModel.length - 1
            }

            onActivated: (index) => root.activated(root.fullModel[index].value)

            background: Rectangle {
                implicitHeight: root.controlHeight
                radius: root.controlRadius
                color: Colors.colors.surfaceAlt
                border.width: root.controlBorderWidth
                border.color: comboBox.hovered ? Colors.colors.borderActive : Colors.colors.border
            }

            contentItem: Text {
                text: comboBox.displayText
                font.pixelSize: 12
                font.family: Config.font
                color: Colors.colors.foreground
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
            }

            indicator : Image {
                x: comboBox.width - width - 10
                y: (comboBox.height - height) / 2
                source: Icons.getIcon("arrowDropDown")
            }

            delegate: ItemDelegate {
                required property var modelData
                required property int index

                width: comboBox.width
                height: 30

                background: Rectangle {
                    radius: 6
                    color: comboBox.highlightedIndex === index ? Colors.colors.hover : "transparent"
                }

                contentItem: Text {
                    text: modelData.label
                    font.pixelSize: 12
                    font.family: Config.font
                    color: Colors.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                }
            }

            popup: Popup {
                y: comboBox.height + 4
                width: comboBox.width
                implicitHeight: contentItem.implicitHeight
                padding: 4

                background: Rectangle {
                    radius: root.controlRadius
                    color: Colors.colors.surface
                    border.width: root.controlBorderWidth
                    border.color: Colors.colors.border
                }

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: comboBox.popup.visible ? comboBox.delegateModel : null
                    currentIndex: comboBox.highlightedIndex
                    boundsBehavior: Flickable.StopAtBounds
                }
            }
        }
    }

}
