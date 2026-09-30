// qml/Timer/StopwatchTab.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../Config"
import Wisp.Time

FocusScope {
    id: stopwatchTab

    // Both tabs are created at startup, so take focus when this tab is shown
    // instead of at creation (which would steal it from the Timer tab).
    onVisibleChanged: if (visible) forceActiveFocus()

    // Space/Enter: start, pause or resume.  L: lap.  R: reset (when stopped).
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            Stopwatch.toggle();
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            Stopwatch.lap();
            event.accepted = true;
        } else if (event.key === Qt.Key_R && Stopwatch.paused) {
            Stopwatch.reset();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Colors.colors.background
        border.color: Colors.colors.border
        border.width: 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => stopwatchTab.Window.window.startSystemMove()
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // With no laps the controls sit in the middle, like the Timer tab.
            Item {
                Layout.fillHeight: true
                visible: lapList.count === 0
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
                text: Stopwatch.elapsedText
                color: Stopwatch.paused ? Colors.colors.accentAlt : Colors.colors.accent
                font.bold: true
                font.family: Config.font
                font.pixelSize: Math.max(24, stopwatchTab.width * 0.13)
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 16
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Start / Pause / Resume
                Rectangle {
                    implicitWidth: 84
                    implicitHeight: 32
                    radius: 8
                    color: Colors.colors.accent

                    Text {
                        anchors.centerIn: parent
                        text: Stopwatch.running ? "Pause" : Stopwatch.paused ? "Resume" : "Start"
                        font.family: Config.font
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.colors.background
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Stopwatch.toggle()
                    }
                }

                // Lap while running, Reset while paused, disabled when idle
                Rectangle {
                    implicitWidth: 84
                    implicitHeight: 32
                    radius: 8
                    color: Colors.colors.accent
                    opacity: Stopwatch.idle ? 0.4 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: Stopwatch.running ? "Lap" : "Reset"
                        font.family: Config.font
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.colors.background
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !Stopwatch.idle
                        onClicked: Stopwatch.running ? Stopwatch.lap() : Stopwatch.reset()
                    }
                }
            }

            ListView {
                id: lapList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                visible: count > 0
                clip: true
                spacing: 2
                model: Stopwatch.laps
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {}

                delegate: Rectangle {
                    required property var modelData

                    width: lapList.width
                    height: 24
                    radius: 6
                    color: Colors.colors.surfaceAlt

                    readonly property color rowColor: modelData.best ? Colors.colors.accent : Colors.colors.accentAlt

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: "Lap " + modelData.number
                            color: rowColor
                            font.family: Config.font
                            font.pixelSize: 12
                            font.bold: modelData.best || modelData.worst
                            Layout.preferredWidth: 60
                        }

                        Text {
                            text: modelData.lapText
                            color: rowColor
                            font.family: Config.font
                            font.pixelSize: 12
                            font.bold: modelData.best || modelData.worst
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: modelData.totalText
                            color: rowColor
                            opacity: 0.7
                            font.family: Config.font
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                visible: lapList.count === 0
            }
        }
    }
}
