// qml/Screenshot/ScreenshotTab.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "../Colors"
import "../GlobalState"

Item {
    id: screenshotTab

    readonly property string scriptPath: Quickshell.env("WISP_SHARE_DIR") + "/scripts/screenshot.sh"

    readonly property var screenshotTypes: [
        { "name": "Region", "icon": "\udb83\ude51", "flags": [] },
        { "name": "Window", "icon": "\ueb7f", "flags": ["-w"] },
        { "name": "Monitor", "icon": "\udb80\udf79", "flags": ["-m"] }
    ]

    property bool isSaveToDisk: false

    function runScreeenshot(flags) {
        let commandFlags = [...flags]

        if (screenshotTab.isSaveToDisk) {
            commandFlags.push("-s")
        }

        runScreeenshotCommand.command = ["bash", screenshotTab.scriptPath].concat(commandFlags)

        // Close the UI popup first
        GlobalState.screenshot.close()

        // Wait a brief moment, then launch detached
        delayTimer.restart()

    }

    Timer {
        id: delayTimer
        interval: 150
        repeat: false
        onTriggered: {
            // startDetached spawns it entirely outside Quickshell's tracking pipe
            runScreeenshotCommand.startDetached()
        }
    }

    Process {
        id: runScreeenshotCommand
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Colors.colors.background
        border.color: Colors.colors.border
        border.width: 2

        ColumnLayout {         
            anchors.fill: parent
            anchors.margins: 10        
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    id: toggleSaveToDisk
                    implicitWidth: 34
                    implicitHeight: 18
                    radius: height / 2
                    color: screenshotTab.isSaveToDisk ? Colors.colors.accent : Colors.colors.surfaceAlt
                    border.width: 1
                    border.color: screenshotTab.isSaveToDisk ? Colors.colors.accent : Colors.colors.borderSoft

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Colors.colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                        x: screenshotTab.isSaveToDisk ? parent.width - width - 2 : 2

                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: screenshotTab.isSaveToDisk = !screenshotTab.isSaveToDisk
                    }
                }

                Text {
                    text: "Save to Disk?"
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 11
                }
            }

            RowLayout {
                id: commandRow
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: screenshotTab.screenshotTypes

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Colors.colors.background
                        border.color: Colors.colors.accent
                        border.width: 2

                        Text {
                            text: modelData.icon
                            color: Colors.colors.accent
                            font.pixelSize: 40
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent   
                            onClicked: (mouse) => {
                                mouse.accepted = true
                                screenshotTab.runScreeenshot(modelData.flags)
                            }
                        }
                    }

                }

            }

        }

    }
}
