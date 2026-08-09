// qml/bar/TimeWorkspace/CalendarPopup.qml

import QtQuick
import QtQuick.Layouts
import "../../Colors"
import "../../Components"
import Wisp.Calendar

BarPopup {
    id: calendarPopup

    signal requestClose()

    // Popup is about to close: snap the grid back to the current month
    // so it doesn't reopen showing wherever it was last navigated to.
    function closePopup() {
        Calendar.goToToday()
    }

    // Popup is opening: pull fresh data rather than showing whatever
    // was last fetched, possibly minutes/hours ago.
    function resetSelection() {
        Calendar.refresh()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 14

        CalendarGrid {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            color: Colors.colors.border
        }

        UpcomingEvents {
            // Layout.fillWidth: true
            Layout.preferredWidth: 200
            Layout.fillHeight: true
        }
    }
}
