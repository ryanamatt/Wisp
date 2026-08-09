// qml/Bar/TimeWorkspace/UpcomingEvents.qml

import QtQuick
import QtQuick.Layouts
import "../../Colors"
import Wisp.Calendar

ColumnLayout {
    id: upcomingEvents

    spacing: 6

    // The backend hands over plain "yyyy-MM-dd" / "HH:mm" strings rather
    // than pre-formatted labels, so these turn them into something
    // readable without depending on a project-wide date-format helper.
    function dateLabel(dateStr) {
        const parts = dateStr.split("-").map(Number)
        const d = new Date(parts[0], parts[1] - 1, parts[2])
        const today = new Date()
        today.setHours(0, 0, 0, 0)

        const diffDays = Math.round((d - today) / 86400000)

        if (diffDays === 0) return "Today"
        if (diffDays === 1) return "Tomorrow"
        if (diffDays > 1 && diffDays < 7) return d.toLocaleDateString(Qt.locale(), "ddd")
        return d.toLocaleDateString(Qt.locale(), "MMM d")
    }

    function timeLabel(timeStr) {
        if (!timeStr) return "All day"
        const bits = timeStr.split(":").map(Number)
        const d = new Date()
        d.setHours(bits[0], bits[1], 0, 0)
        return d.toLocaleTimeString(Qt.locale(), "h:mm AP")
    }

    Text {
        text: "Upcoming"
        color: Colors.colors.foregroundMuted
        font.pixelSize: 10
        font.family: "Noto Sans Mono"
    }

    Text {
        visible: Calendar.error.length > 0
        Layout.fillWidth: true
        text: Calendar.error
        color: Colors.colors.error
        wrapMode: Text.WordWrap
        font.pixelSize: 11
        font.family: "Noto Sans Mono"
    }

    Text {
        visible: Calendar.error.length === 0 && !Calendar.loading && Calendar.upcomingEvents.length === 0
        text: "No upcoming events"
        color: Colors.colors.foregroundMuted
        font.pixelSize: 11
        font.family: "Noto Sans Mono"
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentHeight: eventsColumn.height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: eventsColumn
            width: parent.width
            spacing: 10

            Repeater {
                model: Calendar.upcomingEvents

                delegate: ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: upcomingEvents.dateLabel(modelData.startDate) + " · " + upcomingEvents.timeLabel(modelData.startTime)
                        color: Colors.colors.accentAlt
                        font.pixelSize: 10
                        font.family: "Noto Sans Mono"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.title
                        color: Colors.colors.foreground
                        font.pixelSize: 12
                        font.family: "Noto Sans Mono"
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
