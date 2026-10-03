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

    // Order matters: it is the left-to-right order of the toggle.
    readonly property var profiles: [
        { id: "power-saver", label: "Power Saver" },
        { id: "balanced", label: "Balanced" },
        { id: "performance", label: "Performance" }
    ]

    ColumnLayout {
        anchors.fill: parent
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

        // Pushes the power profile section to the bottom of the popup.
        Item {
            Layout.fillHeight: true
        }

        // ----- Power profile -----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Battery.hasPowerProfiles

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.colors.border
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter 
                text: "Power Profile"
                color: Colors.colors.foregroundMuted
                font.family: Config.font
                font.pixelSize: 11
            }

            Rectangle {
                id: profileSwitch
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: height / 2
                color: Colors.colors.surfaceAlt
                border.width: 1
                border.color: Colors.colors.border

                readonly property int inset: 3
                readonly property real cellWidth: (width - inset * 2) / batteryPopup.profiles.length
                readonly property int currentIndex: {
                    for (let i = 0; i < batteryPopup.profiles.length; i++) {
                        if (batteryPopup.profiles[i].id === Battery.powerProfile)
                            return i
                    }
                    return -1
                }

                // Sliding highlight behind the selected option.
                Rectangle {
                    visible: profileSwitch.currentIndex >= 0
                    x: profileSwitch.inset + Math.max(0, profileSwitch.currentIndex) * profileSwitch.cellWidth
                    y: profileSwitch.inset
                    width: profileSwitch.cellWidth
                    height: profileSwitch.height - profileSwitch.inset * 2
                    radius: height / 2
                    color: Colors.colors.accent

                    Behavior on x {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }

                Repeater {
                    model: batteryPopup.profiles

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index

                        readonly property bool selected: cell.index === profileSwitch.currentIndex
                        // If the supported list couldn't be read, don't lock anything out.
                        readonly property bool supported: Battery.availableProfiles.length === 0
                            || Battery.availableProfiles.indexOf(cell.modelData.id) >= 0

                        x: profileSwitch.inset + cell.index * profileSwitch.cellWidth
                        y: profileSwitch.inset
                        width: profileSwitch.cellWidth
                        height: profileSwitch.height - profileSwitch.inset * 2
                        opacity: cell.supported ? 1.0 : 0.4

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Colors.colors.hover
                            visible: cellMouse.containsMouse && !cell.selected && cell.supported
                        }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            text: cell.modelData.label
                            elide: Text.ElideRight
                            color: cell.selected ? Colors.colors.onAccent : Colors.colors.foregroundMuted
                            font.family: Config.font
                            font.pixelSize: 11
                            font.bold: cell.selected
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            enabled: cell.supported
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Battery.setPowerProfile(cell.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
