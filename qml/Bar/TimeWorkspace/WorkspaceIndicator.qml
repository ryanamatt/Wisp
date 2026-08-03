// qml/bar/TimeWorkspace/WorkspaceIndicator.qml

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../Colors"

RowLayout {
    id: root

    required property var screen
    spacing: 6

    property var monitor: Hyprland.monitorFor(root.screen)

    property var activeWorkspace: (root.monitor && root.monitor.activeWorkspace) 
        ? root.monitor.activeWorkspace 
        : null

    property int activeId: activeWorkspace ? activeWorkspace.id : -1

    property int startWorkspace: {
        switch (root.screen.name) {
            case "DP-3": return 1
            case "DP-2": return 6
            default: return 1
        }
    }

    property bool hasSpecialActive: activeId < 0

    // Helper function to extract a nice short label from the workspace name
    function getSpecialLabel(ws) {
        if (!ws || !ws.name) return ""
        let name = ws.name.toLowerCase()
        if (name.includes("spotify")) return "S"
        if (name.includes("discord")) return "D"
        if (name.includes("desktop") || name.includes("~")) return "~"
        // Fallback: use the first character of the name if custom
        return ws.name.charAt(0).toUpperCase()
    }

    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        // CONDITIONAL EXTRA DOT WITH TEXT LABEL
        Loader {
            active: root.hasSpecialActive
            Layout.preferredWidth: active ? 24 : 0
            Layout.preferredHeight: 8
            Layout.alignment: Qt.AlignVCenter

            sourceComponent: Item {
                id: specialSlot
                property bool active: true

                anchors.fill: parent

                Rectangle {
                    id: specialDot
                    anchors.centerIn: parent

                    width: 24
                    height: 8
                    radius: height / 2
                    color: Colors.colors.accent

                    transformOrigin: Item.Center

                    Text {
                        anchors.centerIn: parent
                        text: root.getSpecialLabel(root.activeWorkspace)
                        font.pixelSize: 10
                        font.bold: true
                        color: Colors.colors.background
                    }

                    ScaleAnimator {
                        target: specialDot
                        from: 0.0
                        to: 1.0
                        duration: 200
                        easing.type: Easing.OutBack
                        running: true
                    }
                }
            }
        }

        // STANDARD 1-5 (OR 6-10) OVALS
        Repeater {
            model: 5

            delegate: Item {
                id: slot
                required property int index
                property int wsNumber: root.startWorkspace + index
                property bool active: wsNumber === root.activeId

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 24
                Layout.preferredHeight: 8

                Rectangle {
                    id: dot
                    anchors.centerIn: parent

                    width: slot.active ? 24 : 16
                    height: 8
                    radius: height / 2

                    transformOrigin: Item.Center

                    color: slot.active ? Colors.colors.accent : Colors.colors.foregroundMuted

                    Behavior on width {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutBack
                            easing.overshoot: 3
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    SequentialAnimation {
                        id: bounceAnim
                        
                        NumberAnimation {
                            target: dot
                            property: "scale"
                            to: 1.35
                            duration: 120
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: dot
                            property: "scale"
                            to: 1.0
                            duration: 220
                            easing.type: Easing.OutBack
                            easing.overshoot: 5
                        }
                    }
                }

                onActiveChanged: {
                    if (active) bounceAnim.restart()
                }
            }
        }
    }
}