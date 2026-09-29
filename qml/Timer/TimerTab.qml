// qml/Screenshot/VideoTab.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../Config"

Item {
    id: timerTab

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Colors.colors.background
        border.color: Colors.colors.border
        border.width: 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => timerTab.Window.window.startSystemMove()
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            // Timer Text / Input Container
            Rectangle {
                id: timerContainer
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.max(timerText.implicitWidth, timerInput.implicitWidth) + 36
                implicitHeight: Math.max(timerText.implicitHeight, timerInput.implicitHeight) + 20
                radius: 10
                color: "transparent"

                property bool isEditing: false

                Text {
                    id: timerText
                    anchors.centerIn: parent
                    text: "00:00"
                    color: Colors.colors.accent
                    font.bold: true
                    font.family: Config.font
                    font.pixelSize: timerTab.width * 0.2
                    visible: !timerContainer.isEditing
                }

                TextInput {
                    id: timerInput
                    anchors.centerIn: parent
                    text: timerText.text
                    color: Colors.colors.accent
                    font.bold: true
                    font.family: Config.font
                    font.pixelSize: timerTab.width * 0.2
                    visible: timerContainer.isEditing
                    focus: timerContainer.isEditing
                    selectByMouse: true
                    
                    onEditingFinished: {
                        timerText.text = text;
                        timerContainer.isEditing = false;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !timerContainer.isEditing
                    onClicked: {
                        timerContainer.isEditing = true;
                        timerInput.forceActiveFocus();
                        timerInput.selectAll();
                        console.log("Clicked Timer Text to Edit");
                    }
                }
            }

            // Control Buttons Row
            RowLayout {
                id: controlButtonLayout
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Rectangle {
                    id: pauseButton
                    implicitWidth: pauseText.implicitWidth + 28
                    implicitHeight: 32
                    radius: 8
                    color: Colors.colors.accent

                    Text {
                        id: pauseText
                        anchors.centerIn: parent
                        text: "Pause"
                        font.family: Config.font
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.colors.background
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: console.log("Clicked Pause Button")
                    }
                }

                Rectangle {
                    id: stopButton
                    implicitWidth: pauseText.implicitWidth + 28
                    implicitHeight: 32
                    radius: 8
                    color: Colors.colors.accent

                    Text {
                        id: stopText
                        anchors.centerIn: parent
                        text: "Stop"
                        font.family: Config.font
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.colors.background
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: console.log("Clicked Stop Button")
                    }
                }
            }
        }
    }
}
