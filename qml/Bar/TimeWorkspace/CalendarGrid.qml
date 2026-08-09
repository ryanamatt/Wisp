// qml/Bar/TimeWorkspace/CalendarGrid.qml

import QtQuick
import QtQuick.Layouts
import "../../Colors"
import Wisp.Calendar

ColumnLayout {
    id: calendarGrid

    spacing: 8

    readonly property var weekdayLabels: ["S", "M", "T", "W", "T", "F", "S"]

    // ----- Header: nav arrows + month/year -----
    RowLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: "‹"
            color: Colors.colors.foreground
            font.pixelSize: 16
            font.family: "Noto Sans Mono"

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: Calendar.previousMonth()
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Calendar.displayedMonthName
            color: Colors.colors.foreground
            font.pixelSize: 13
            font.bold: true
            font.family: "Noto Sans Mono"
        }

        Text {
            text: "›"
            color: Colors.colors.foreground
            font.pixelSize: 16
            font.family: "Noto Sans Mono"

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: Calendar.nextMonth()
            }
        }
    }

    // ----- Weekday labels -----
    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            model: calendarGrid.weekdayLabels

            delegate: Text {
                required property string modelData

                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Colors.colors.foregroundMuted
                font.pixelSize: 10
                font.family: "Noto Sans Mono"
            }
        }
    }

    // ----- Day grid: 6 weeks x 7 days, Sunday-first -----
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 0

        Repeater {
            model: Calendar.monthDays

            delegate: Item {
                required property var modelData

                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.8
                    height: width
                    radius: width / 2
                    color: modelData.isToday ? Colors.colors.accent : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    text: modelData.day
                    color: modelData.isToday
                        ? Colors.colors.background
                        : (modelData.inMonth ? Colors.colors.foreground : Colors.colors.foregroundMuted)
                    opacity: modelData.inMonth ? 1 : 0.4
                    font.pixelSize: 11
                    font.family: "Noto Sans Mono"
                }

                Rectangle {
                    visible: modelData.hasEvents
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    width: 4
                    height: 4
                    radius: 2
                    color: modelData.isToday ? Colors.colors.background : Colors.colors.accentAlt
                }
            }
        }
    }
}
