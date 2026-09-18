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
        Layout.alignment: Qt.AlignHCenter
        spacing: 14

        Text {
            id: settingLabel
            text: settingText
            font.pixelSize: 15
            font.family: Config.font
            font.bold: true
            color: Colors.colors.foregroundMuted
        }

        ComboBox {
            id: comboBox

            Layout.preferredWidth: 240
            implicitHeight: 32

            model: root.fullModel
            textRole: "label"

            currentIndex: {
                const idx = root.indexForFormat(pendingValue)
                return idx !== -1 ? idx : root.fullModel.length - 1
            }

            onActivated: (index) => root.activated(root.fullModel[index].value)

            background: Rectangle {
                implicitHeight: 32
                radius: 8
                color: Colors.colors.surfaceAlt
                border.width: 1
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
                    radius: 8
                    color: Colors.colors.surface
                    border.width: 1
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
