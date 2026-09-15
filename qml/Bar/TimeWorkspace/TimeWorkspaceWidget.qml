// qml/bar/TimeWorkspace/TimeWorkspaceWidget.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../Components"
import "../../IpcState"
import "../../Colors"
import "../../Config"
import Wisp.Time

BarWidgetContainer {
    id: timeWorkspace

    required property var screen

    implicitWidth: 200

    radius: implicitWidth / 2

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4 // Space between time and indicators

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Time.time
            color: Colors.colors.foreground
            font.pixelSize: 14
            font.family: Config.font
        }

        WorkspaceIndicator { 
            screen: timeWorkspace.screen 
            Layout.alignment: Qt.AlignHCenter
        }
    }

    isOpenHere: IpcState.timeWorkspace.isOpenOn(timeWorkspace.screen)

    popupWindows: [calendarPopup]

    onRequestOpen: IpcState.timeWorkspace.open(timeWorkspace.screen)
    onRequestClose: IpcState.timeWorkspace.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.resetSelection()
            popup.forceActiveFocus()
            activateFocusGrab()
        } else {
            popup.closePopup()
            releaseFocusGrab()
        }
    }

    WidgetPopup {
        id: calendarPopup
        widget: timeWorkspace
        implicitWidth: 600
        implicitHeight: 300

        CalendarPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: timeWorkspace.forceClose()
        }
    }
}
