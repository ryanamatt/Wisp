// qml/Bar/Notifications/NotificationsPopup.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../Components"
import "../../Colors"
import "../../Config"
import "../../Notifications"

BarPopup {
    id: notifPopup

    signal requestClose()

    function closePopup() {
        notifPopup.requestClose()
    }

    Keys.onEscapePressed: notifPopup.closePopup()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ----- Toggle + Clear row -----
        RowLayout {
            id: headerRow
            Layout.margins: 5
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 8

            ToggleButton {
                condition: NotificationService.dnd
                label: "Do Not Disturb"
                onToggled: (newValue) => NotificationService.dnd = newValue
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: clearButton
                implicitHeight: 22
                implicitWidth: headerRow.implicitWidth / 3
                radius: 6
                opacity: NotificationService.count > 0 ? 1 : 0.4
                color: clearHover.hovered ? (confirmingClear ? Colors.colors.hover : Colors.colors.surfaceAlt) : "transparent"
                border.width: 1
                border.color: confirmingClear ? Colors.colors.error : Colors.colors.borderSoft

                property bool confirmingClear: false

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Timer {
                    id: confirmResetTimer
                    interval: 2500
                    onTriggered: clearButton.confirmingClear = false
                }

                Text {
                    anchors.centerIn: parent
                    text: clearButton.confirmingClear ? "Confirm?" : "Clear all"
                    color: clearButton.confirmingClear ? Colors.colors.error : Colors.colors.foregroundMuted
                    font.pixelSize: 11
                    font.family: Config.font
                }

                HoverHandler { id: clearHover }

                MouseArea {
                    anchors.fill: parent
                    enabled: NotificationService.count > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (clearButton.confirmingClear) {
                            confirmResetTimer.stop()
                            clearButton.confirmingClear = false
                            NotificationService.clearAll()
                        } else {
                            clearButton.confirmingClear = true
                            confirmResetTimer.restart()
                        }
                    }
                }
            }
        }

        // ----- List -----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: listView
                anchors.fill: parent
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds

                // Newest first.
                model: ScriptModel {
                    values: [...NotificationService.model.values].reverse()
                }

                delegate: NotificationCard {
                    required property var modelData

                    notif: modelData
                    width: ListView.view.width

                    onDismissed: NotificationService.dismiss(notif)
                }

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: 150 }
                        NumberAnimation { property: "x"; to: 40; duration: 150 }
                    }
                }

                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 180; easing.type: Easing.OutCubic }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: NotificationService.count === 0
                color: Colors.colors.foregroundMuted
                font.pixelSize: 12
                font.family: Config.font
                text: NotificationService.dnd ? "Do Not Disturb is on" : "No notifications"
            }
        }
    }
}
