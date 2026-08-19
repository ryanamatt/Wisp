// qml/CommandCenter/CommandCenter.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../GlobalState"

PanelWindow {
    id: commandCenter

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: true

    // Starts closed by default, opens only when IPC command triggers it
    visible: GlobalState.commandCenter.isOpen

    FocusScope {
        id: focusScope 
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: GlobalState.commandCenter.close()

        // Dim Screen behind
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Colors.colors.surfaceAlt.r, Colors.colors.surfaceAlt.g, Colors.colors.surfaceAlt.b, 0.2)

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalState.commandCenter.close()
            }    
        }

        Rectangle {
            id: winRect 
            anchors.centerIn: parent
            width: Math.min(800, parent.width - 80)
            height: Math.min(600, parent.height - 80)
            radius: 14
            color: Colors.colors.background
            border.color: Colors.colors.border
            border.width: 2

            // Swallow clicks so the dim screen's MouseArea doesn't see them
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => mouse.accepted = true
            }

            
        }

    } // commandCenter
}