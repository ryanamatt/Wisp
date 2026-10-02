// qml/Bar/Battery/BatteryPopup.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Components"
import "../../Colors"
import "../../Config"
import "../../Icons"
import Wisp.Battery

BarPopup {
    id: batteryPopup

    signal requestClose()

    Keys.onEscapePressed: batteryPopup.requestClose()

    readonly property var accessories: Battery.accessories

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Battery & Accessories"
            color: Colors.colors.foreground
            font.family: Config.font
            font.pixelSize: 13
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }

        ColumnLayout {
            id: col
            Layout.fillWidth: true
            spacing: 8
            visible: batteryPopup.accessories.length > 0

            Repeater {
                model: batteryPopup.accessories

                delegate: RowLayout {
                    id: row
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 10

                    Image {
                        source: Icons.getIcon(row.modelData.icon)
                        fillMode: Image.PreserveAspectFit
                        Layout.preferredWidth: col.implicitWidth * 0.05
                        Layout.preferredHeight: col.implicitWidth * 0.05
                        sourceSize.width: width * Screen.devicePixelRatio
                        sourceSize.height: height * Screen.devicePixelRatio
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        color: Colors.colors.foreground
                        font.family: Config.font
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Colors.colors.surface

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(3, parent.width * Math.max(0, Math.min(100, row.modelData.percent)) / 100)
                            height: 6
                            radius: 3
                            color: row.modelData.percent <= 20
                                ? Colors.colors.error
                                : (row.modelData.charging ? Colors.colors.accentAlt : Colors.colors.accent)
                        }
                    }

                    Text {
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                        text: row.modelData.percent + "%"
                        color: row.modelData.percent <= 20 ? Colors.colors.error : Colors.colors.foregroundMuted
                        font.family: Config.font
                        font.pixelSize: 12
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: batteryPopup.accessories.length === 0
            text: "No battery-reporting devices found"
            horizontalAlignment: Text.AlignHCenter
            color: Colors.colors.foregroundMuted
            font.family: Config.font
            font.pixelSize: 12
        }
    }
}
