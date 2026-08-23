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

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "\uf186"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 16
                    color: BrightnessSingleton.nightlightEnabled ? Colors.colors.accentAlt : Colors.colors.foreground
                }

                Text {
                    Layout.fillWidth: true
                    text: "Night Light"
                    color: Colors.colors.foreground
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 13
                }

                Rectangle {
                    id: nightlightToggleTrack
                    implicitWidth: 34
                    implicitHeight: 18
                    radius: height / 2
                    color: BrightnessSingleton.nightlightEnabled ? Colors.colors.accent : Colors.colors.surfaceAlt
                    border.width: 1
                    border.color: BrightnessSingleton.nightlightEnabled ? Colors.colors.accent : Colors.colors.borderSoft

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Colors.colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                        x: BrightnessSingleton.nightlightEnabled ? parent.width - width - 2 : 2

                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BrightnessSingleton.toggleNightlight()
                    }
                }
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
    }
}
