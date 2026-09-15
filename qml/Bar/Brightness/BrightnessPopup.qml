// qml/Bar/Brightness/BrightnessPopup.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import "../../Components"
import "../../Colors"
import "../../Config"
import "../../Icons"
import Wisp.Brightness

BarPopup {
    id: brightnessPopup

    signal requestClose()

    Keys.onEscapePressed: brightnessPopup.requestClose()

    function refreshBrightness() {
        Brightness.refreshBrightness()
    }

    Component.onCompleted: refreshBrightness()

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 14

        // ----- Brightness -----
        RowLayout {
            id: row
            Layout.fillWidth: true
            spacing: 10
            visible: Brightness.hasBacklight

            Image {
                source: Icons.getIcon("brightness")
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: row.width * 0.1
                Layout.preferredHeight: Layout.preferredWidth

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Brightness.setBrightness(1)
                }
            }

            DragBar {
                Layout.fillWidth: true
                enabled: Brightness.hasBacklight
                value: Brightness.brightnessValue
                onMoved: v => Brightness.setBrightness(v)
            }

            Text {
                Layout.preferredWidth: 34
                text: Brightness.brightnessPercent + "%"
                color: Colors.colors.foregroundMuted
                font.family: Config.font
                font.pixelSize: 12
            }
        }

        Text {
            Layout.fillWidth: true
            visible: !Brightness.hasBacklight
            text: "No backlight on this display"
            horizontalAlignment: Text.AlignHCenter
            color: Colors.colors.foregroundMuted
            font.family: Config.font
            font.pixelSize: 12
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }

        // ----- Night Light -----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Center Toggle Button
            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                ToggleButton {
                    Layout.fillWidth: false
                    Layout.preferredWidth: 110 // Adjust this if the text gets cut off
                    condition: Brightness.nightlightEnabled
                    label: "Night Light"
                    onToggled: (newValue) => Brightness.toggleNightlight()
                }

                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: Brightness.nightlightEnabled

                Text {
                    text: "Warmth"
                    color: Colors.colors.foregroundMuted
                    font.family: Config.font
                    font.pixelSize: 11
                }

                DragBar {
                    Layout.fillWidth: true
                    enabled: Brightness.nightlightEnabled
                    fillColor: Colors.colors.accentAlt
                    value: Brightness.nightlightWarmth
                    onMoved: v => Brightness.setNightlightWarmth(v)
                }

                Text {
                    Layout.preferredWidth: 48
                    text: Brightness.currentKelvin + "K"
                    color: Colors.colors.foregroundMuted
                    font.family: Config.font
                    font.pixelSize: 12
                }
            }
        }

        // --- Backlight ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: Brightness.hasKeyboardBacklight

            Text {
                text: "Kbd Light"
                color: Colors.colors.foregroundMuted
                font.family: Config.font
                font.pixelSize: 11
            }

            DragBar {
                Layout.fillWidth: true
                enabled: Brightness.hasKeyboardBacklight
                fillColor: Colors.colors.accentAlt
                value: Brightness.keyboardBacklightValue
                onMoved: v => Brightness.updateKeyboardBacklightValue(v)
            }

            Text {
                text: Brightness.keyboardBacklightValue
                color: Colors.colors.foregroundMuted
                font.family: Config.font
                font.pixelSize: 11
            }
        }
    }
}
