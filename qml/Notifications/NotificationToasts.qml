// qml/Notifications/NotificationToasts.qml

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Config"
import "../IpcState"

// Popup notifications. One overlay window, shown on whichever monitor was
// focused when the first toast of a burst arrived.
Scope {
    id: root

    property var targetScreen: Quickshell.screens[0]
    property int prevCount: 0

    readonly property int toastWidth: 360
    readonly property int barHeight: 40
    readonly property real topMargin: Config.barOrientation === "top" ? root.barHeight + 8 : 8

    Connections {
        target: NotificationService

        function onToastsChanged() {
            const c = NotificationService.toasts.length
            if (c > 0 && root.prevCount === 0)
                root.targetScreen = IpcState.notificationsWidget.resolveScreen(null)
            if (c === 0)
                linger.restart()
            root.prevCount = c
        }
    }

    // Keep the window mapped long enough for the exit animation.
    Timer {
        id: linger
        interval: 400
    }

    PanelWindow {
        id: win

        screen: root.targetScreen
        visible: NotificationService.toasts.length > 0 || linger.running
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wisp-notifications"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            right: true
        }
        margins {
            top: root.topMargin
            right: 10
        }

        implicitWidth: root.toastWidth
        implicitHeight: Math.max(200, (win.screen ? win.screen.height : 1080) - root.topMargin - 20)

        // Only the toasts themselves take input; the rest of the window is
        // click-through.
        mask: Region { item: list }

        ListView {
            id: list
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: contentHeight
            interactive: false
            spacing: 8

            model: ScriptModel {
                values: NotificationService.toasts
            }

            delegate: NotificationCard {
                required property var modelData

                notif: modelData
                toast: true
                width: ListView.view.width

                onDismissed: NotificationService.dismiss(notif)
                onExpired: NotificationService.expireToast(notif)
            }

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                    NumberAnimation { property: "x"; from: 60; to: 0; duration: 260; easing.type: Easing.OutCubic }
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: 180 }
                    NumberAnimation { property: "x"; to: 60; duration: 220; easing.type: Easing.InCubic }
                }
            }

            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutCubic }
            }
        }
    }
}
