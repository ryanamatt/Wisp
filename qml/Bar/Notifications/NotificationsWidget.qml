// qml/Bar/Notifications/NotificationsWidget.qml


import QtQuick
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../Colors"

BarWidgetContainer {
    id: notifWidget 

    implicitWidth: 50

    icon.text: "\uf49a"

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
