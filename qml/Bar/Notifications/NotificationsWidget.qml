// qml/Bar/Notifications/NotificationsWidget.qml


import QtQuick
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../Colors"
import "../../Icons"

BarWidgetContainer {
    id: notifWidget 

    iconImage.source: Icons.getIcon("notification")
    iconImage.width: notifWidget.implicitWidth * 0.6

    Process {
        id: runNotif
        command: ["bash", "-c", "swaync-client -t -sw"]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (runNotif.running) {
                runNotif.running = false
            }
            runNotif.running = true
        }
    }
}
