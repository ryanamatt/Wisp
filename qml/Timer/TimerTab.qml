// qml/Timer/TimerTab.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../Config"
import Wisp.Time

FocusScope {
    id: timerTab
    focus: true

    Component.onCompleted: forceActiveFocus()

    Connections {
        target: CountdownTimer
        function onTimerFinished() {
            sendEndNotification.running = true
        }
    }

    Process {
        id: sendEndNotification
        command: ["notify-send", "-a", "Wisp", "-i", "clock", "Timer", "Timer has Ended"]
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            // If we are currently editing, let the TextInput / editingFinished handle it (committing edit without starting)
            if (timerContainer.isEditing) {
                return;
            }

            if (CountdownTimer.totalMs > 0) {
                CountdownTimer.toggle();
                event.accepted = true;
            }
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

                // The duration can only be changed while nothing is counting down.
                readonly property bool canEdit: CountdownTimer.idle || CountdownTimer.finished

                function commitEdit() {
                    if (!isEditing) return;
                    // On invalid input the previous duration is kept.
                    CountdownTimer.setDurationText(timerInput.text);
                    isEditing = false;
                }

                function cancelEdit() {
                    isEditing = false;
                }

                // Never leave the editor open if the timer starts underneath it.
                onCanEditChanged: if (!canEdit) cancelEdit()

                Text {
                    id: timerText
                    anchors.centerIn: parent
                    text: CountdownTimer.remainingText
                    color: CountdownTimer.finished ? Colors.colors.accentAlt : Colors.colors.accent
                    font.bold: true
                    font.family: Config.font
                    font.pixelSize: timerTab.width * 0.2
                    visible: !timerContainer.isEditing
                }

                TextInput {
                    id: timerInput
                    anchors.centerIn: parent
                    color: Colors.colors.accent
                    font.bold: true
                    font.family: Config.font
                    font.pixelSize: timerTab.width * 0.2
                    visible: timerContainer.isEditing
                    focus: timerContainer.isEditing
                    selectByMouse: true

                    // Focus leaving the field applies the edit.
                    onEditingFinished: timerContainer.commitEdit()

                    // Enter applies the edit and is consumed here, so it does not
                    // bubble up to timerTab and start the timer. Starting needs a second Enter.
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            timerContainer.commitEdit();
                            event.accepted = true;
                        }
                    }

                    // Escape cancels the edit instead of closing the window.
                    Keys.onEscapePressed: (event) => {
                        timerContainer.cancelEdit();
                        event.accepted = true;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: timerContainer.canEdit ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: !timerContainer.isEditing && timerContainer.canEdit
                    onClicked: {
                        timerInput.text = CountdownTimer.totalText;
                        timerContainer.isEditing = true;
                        timerInput.forceActiveFocus();
                        timerInput.selectAll();
                    }
                }
            }

            // Control Buttons Row
            RowLayout {
                id: controlButtonLayout
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Start / Pause / Resume / Restart
                Rectangle {
                    id: pauseButton
                    implicitWidth: 84
                    implicitHeight: 32
                    radius: 8
                    color: Colors.colors.accent
                    opacity: CountdownTimer.totalMs > 0 ? 1.0 : 0.4

                    Text {
                        id: pauseText
                        anchors.centerIn: parent
                        text: CountdownTimer.running ? "Pause"
                            : CountdownTimer.paused ? "Resume"
                            : CountdownTimer.finished ? "Restart"
                            : "Start"
                        font.family: Config.font
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.colors.background
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: CountdownTimer.totalMs > 0
                        onClicked: {
                            if (timerContainer.isEditing) timerContainer.commitEdit();
                            CountdownTimer.toggle();
                        }
                    }
                }

                // Stop (resets to the configured duration)
                Rectangle {
                    id: stopButton
                    implicitWidth: 84
                    implicitHeight: 32
                    radius: 8
                    color: Colors.colors.accent
                    opacity: CountdownTimer.idle ? 0.4 : 1.0

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
                        enabled: !CountdownTimer.idle
                        onClicked: CountdownTimer.stop()
                    }
                }
            }
        }
    }
}
