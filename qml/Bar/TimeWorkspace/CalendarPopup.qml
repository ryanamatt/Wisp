// qml/bar/TimeWorkspace/CalendarPopup.qml

import QtQuick
import QtQuick.Layouts
import "../../Colors"
import "../../Components"

BarPopup {
    id: calendarPopup

    signal requestClose()

    function closePopup() {}

    function resetSelection() {}


    implicitWidth: 50
}
