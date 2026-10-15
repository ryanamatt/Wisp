// qml/Notifications/NotificationService.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Owns the org.freedesktop.Notifications DBus name.
// Every notification is tracked, so `model` doubles as the history shown in
// the notification center. `toasts` is the subset currently shown as popups.
Singleton {
    id: root

    // ----- Settings -----
    property bool dnd: false
    // Critical notifications still pop up while Do Not Disturb is on.
    property bool criticalBypassesDnd: true
    property int maxToasts: 4

    // ----- History (live ObjectModel of Notification objects) -----
    readonly property var model: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    // Notification ids increase monotonically, so "unread" is simply
    // "newer than the last id seen when the center was opened".
    property int lastReadId: 0
    readonly property int unreadCount: {
        const list = server.trackedNotifications.values
        let n = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i].id > root.lastReadId)
                n++
        }
        return n
    }

    // ----- Toast state -----
    // Notifications currently shown as popups, newest first.
    property var toasts: []

    // Receive time (ms since epoch) per notification id.
    property var receivedAt: ({})

    // Ticks so relative timestamps ("5m") stay fresh.
    property real now: Date.now()

    function markAllRead() {
        const list = server.trackedNotifications.values
        let maxId = root.lastReadId
        for (let i = 0; i < list.length; i++)
            maxId = Math.max(maxId, list[i].id)
        root.lastReadId = maxId
    }

    function showToast(n) {
        if (root.toasts.indexOf(n) !== -1)
            return
        root.toasts = [n].concat(root.toasts).slice(0, root.maxToasts)
    }

    // Hides the popup only. The notification stays in the center.
    function hideToast(n) {
        root.toasts = root.toasts.filter(t => t && t !== n)
    }

    // Called when a toast times out.
    function expireToast(n) {
        root.hideToast(n)
        // Transient notifications are not meant to be kept around.
        if (n && n.transient)
            n.dismiss()
    }

    // Removes the notification everywhere (popup and center).
    function dismiss(n) {
        root.hideToast(n)
        if (n)
            n.dismiss()
    }

    function clearAll() {
        root.toasts = []
        // dismiss() mutates the model, so iterate over a copy.
        const list = [...server.trackedNotifications.values]
        for (let i = 0; i < list.length; i++)
            list[i].dismiss()
    }

    onDndChanged: {
        if (root.dnd) {
            root.toasts = root.toasts.filter(t =>
                t && t.urgency === NotificationUrgency.Critical && root.criticalBypassesDnd)
        }
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        actionIconsSupported: false
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        imageSupported: true

        onNotification: n => {
            // Untracked notifications are discarded, so this is required.
            n.tracked = true

            root.now = Date.now()
            root.receivedAt[n.id] = root.now

            n.closed.connect(() => {
                root.hideToast(n)
                delete root.receivedAt[n.id]
            })

            const critical = n.urgency === NotificationUrgency.Critical
            if (!root.dnd || (critical && root.criticalBypassesDnd))
                root.showToast(n)
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.count > 0
        onTriggered: root.now = Date.now()
    }

    // `wisp toggle dnd`, `wisp open dnd` (enable), `wisp close dnd` (disable)
    IpcHandler {
        target: "dnd"
        function open(): void { root.dnd = true }
        function close(): void { root.dnd = false }
        function toggle(): void { root.dnd = !root.dnd }
    }
}
