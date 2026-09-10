// qml/Bar/Brightness/BrightnessPopup.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import "../../Components"
import "../../Colors"

BarPopup {
    id: brightnessPopup

    signal requestClose()

    Keys.onEscapePressed: brightnessPopup.requestClose()

    function refreshBrightness() {
        BrightnessSingleton.refreshBrightness()
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
            Layout.fillWidth: true
            spacing: 10
            visible: BrightnessSingleton.hasBacklight

            Text {
                text: "\uf185"
                font.family: "Iosevka Nerd Font Propo"
                font.pixelSize: 18
                color: Colors.colors.foreground

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BrightnessSingleton.setBrightness(1)
                }
            }

            DragBar {
                Layout.fillWidth: true
                enabled: BrightnessSingleton.hasBacklight
                value: BrightnessSingleton.brightnessValue
                onMoved: v => BrightnessSingleton.setBrightness(v)
            }

            Text {
                Layout.preferredWidth: 34
                text: BrightnessSingleton.brightnessPercent + "%"
                color: Colors.colors.foregroundMuted
                font.family: "Noto Sans Mono"
                font.pixelSize: 12
            }
        }

        Text {
            Layout.fillWidth: true
            visible: !BrightnessSingleton.hasBacklight
            text: "No backlight on this display"
            horizontalAlignment: Text.AlignHCenter
            color: Colors.colors.foregroundMuted
            font.family: "Noto Sans Mono"
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

            ToggleButton {
                condition: BrightnessSingleton.nightlightEnabled
                label: "Night Light"
                onToggled: (newValue) => BrightnessSingleton.toggleNightlight()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: BrightnessSingleton.nightlightEnabled

                Text {
                    text: "Warmth"
                    color: Colors.colors.foregroundMuted
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 11
                }

                DragBar {
                    Layout.fillWidth: true
                    enabled: BrightnessSingleton.nightlightEnabled
                    fillColor: Colors.colors.accentAlt
                    value: BrightnessSingleton.nightlightWarmth
                    onMoved: v => BrightnessSingleton.setNightlightWarmth(v)
                }

                Text {
                    Layout.preferredWidth: 48
                    text: BrightnessSingleton.currentKelvin + "K"
                    color: Colors.colors.foregroundMuted
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 12
                }
            }
        }

        // --- Backlight ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: BrightnessSingleton.hasKeyboardBacklight

            Text {
                text: "Kbd Light"
                color: Colors.colors.foregroundMuted
                font.family: "Noto Sans Mono"
                font.pixelSize: 11
            }

            DragBar {
                Layout.fillWidth: true
                enabled: BrightnessSingleton.hasKeyboardBacklight
                fillColor: Colors.colors.accentAlt
                value: BrightnessSingleton.keyboardBacklightValue
                onMoved: v => BrightnessSingleton.updateKeyboardBacklightValue(v)
            }

            Text {
                text: BrightnessSingleton.keyboardBacklightValue
                color: Colors.colors.foregroundMuted
                font.family: "Noto Sans Mono"
                font.pixelSize: 11
            }
        }
    }
}
