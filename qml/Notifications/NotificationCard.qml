// qml/Notifications/NotificationCard.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../Colors"
import "../Config"
import "../Icons"

// One notification. Used both for toasts (toast: true, auto-expires with a
// progress bar) and for rows in the notification center.
Rectangle {
    id: card

    required property var notif

    property bool toast: false
    property bool expanded: false
    property real progress: 1

    // Remove the notification entirely.
    signal dismissed()
    // Toast ran out of time (or was clicked with nothing to do).
    signal expired()

    // The Notification object is destroyed as soon as it closes, but this
    // delegate lives on for the exit transition, so notif can become null.
    readonly property bool alive: card.notif !== null && card.notif !== undefined

    // Last known values. They stop updating once notif goes away, so the card
    // keeps its content while it fades out instead of blanking or warning.
    QtObject {
        id: snap
        property string appName: ""
        property string summary: ""
        property string body: ""
        property string iconSource: ""
        property string timeText: ""
        property bool hasImage: false
        property bool critical: false
    }

    Binding { target: snap; property: "appName"; value: card.alive ? card.notif.appName : ""; when: card.alive; restoreMode: Binding.RestoreNone }
    Binding { target: snap; property: "summary"; value: card.alive ? card.notif.summary : ""; when: card.alive; restoreMode: Binding.RestoreNone }
    Binding { target: snap; property: "body"; value: card.alive ? card.notif.body : ""; when: card.alive; restoreMode: Binding.RestoreNone }
    Binding { target: snap; property: "iconSource"; value: card.resolveIcon(); when: card.alive; restoreMode: Binding.RestoreNone }
    Binding { target: snap; property: "timeText"; value: card.computeTimeText(); when: card.alive; restoreMode: Binding.RestoreNone }
    Binding { target: snap; property: "hasImage"; value: card.alive && card.notif.image.length > 0; when: card.alive; restoreMode: Binding.RestoreNone }
    Binding { target: snap; property: "critical"; value: card.alive && card.notif.urgency === NotificationUrgency.Critical; when: card.alive; restoreMode: Binding.RestoreNone }

    readonly property bool critical: snap.critical

    // expireTimeout is in seconds; <= 0 means "server decides".
    // Set once in Component.onCompleted.
    property int timeoutMs: 0

    function computeTimeout() {
        if (!card.alive)
            return 0
        if (card.notif.expireTimeout > 0)
            return card.notif.expireTimeout * 1000
        if (card.notif.urgency === NotificationUrgency.Critical)
            return 0
        return card.notif.urgency === NotificationUrgency.Low ? 1000 : 2000
    }

    readonly property var defaultAction: {
        if (!card.alive)
            return null
        const list = card.notif.actions
        for (let i = 0; i < list.length; i++) {
            if (list[i].identifier === "default")
                return list[i]
        }
        return null
    }

    readonly property var buttonActions: {
        if (!card.alive)
            return []
        const list = card.notif.actions
        const out = []
        for (let i = 0; i < list.length; i++) {
            if (list[i].identifier !== "default")
                out.push(list[i])
        }
        return out
    }

    readonly property string timeText: snap.timeText

    function computeTimeText() {
        if (!card.alive)
            return ""
        const t = NotificationService.receivedAt[card.notif.id]
        if (t === undefined)
            return ""
        const s = Math.max(0, Math.floor((NotificationService.now - t) / 1000))
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + "m"
        if (s < 86400) return Math.floor(s / 3600) + "h"
        return Math.floor(s / 86400) + "d"
    }

    // image hint -> appIcon -> desktop entry icon -> bell.
    function resolveIcon() {
        if (!card.alive)
            return ""
        const img = card.notif.image
        if (img && img.length > 0)
            return img

        const ic = card.notif.appIcon
        if (ic && ic.length > 0) {
            if (ic.startsWith("/"))
                return "file://" + ic
            if (ic.startsWith("file://") || ic.startsWith("image://"))
                return ic
            const p = Quickshell.iconPath(ic, true)
            if (p && p.length > 0)
                return p
        }

        const de = card.notif.desktopEntry
        if (de && de.length > 0) {
            const p = Quickshell.iconPath(de, true)
            if (p && p.length > 0)
                return p
        }
        return ""
    }

    readonly property string iconSource: snap.iconSource
    readonly property bool hasRealIcon: card.iconSource.length > 0

    function activate() {
        if (!card.alive)
            return
        if (card.defaultAction) {
            card.defaultAction.invoke()
            card.dismissed()
        } else if (card.toast) {
            card.expired()
        } else {
            card.expanded = !card.expanded
        }
    }

    function runAction(action) {
        if (!card.alive)
            return
        action.invoke()
        if (!card.notif.resident)
            card.dismissed()
    }

    implicitHeight: content.implicitHeight + 22
    radius: 14

    color: card.toast
        ? Colors.colors.backgroundAlt
        : (cardHover.hovered ? Colors.colors.hover : Colors.colors.surface)
    border.width: card.toast ? 2 : (card.critical ? 1 : 0)
    border.color: card.critical ? Colors.colors.error : Colors.colors.background

    Behavior on color { ColorAnimation { duration: 100 } }

    HoverHandler {
        id: cardHover
        onHoveredChanged: {
            if (!life.running)
                return

            if (cardHover.hovered)
                life.pause()
            else
                life.resume()
        }
    }
    // Toast lifetime. Hovering pauses the countdown.
    NumberAnimation {
        id: life
        target: card
        property: "progress"
        from: 1
        to: 0
        duration: card.timeoutMs
        onFinished: card.expired()
    }

    Component.onCompleted: {
        card.timeoutMs = card.computeTimeout()
        if (card.toast && card.timeoutMs > 0)
            life.start()
    }

    // Declared before the content so buttons sit on top and win clicks.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                card.dismissed()
            else
                card.activate()
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop
                radius: 10
                color: Colors.colors.surfaceAlt
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: snap.hasImage ? 0 : 7
                    source: card.hasRealIcon ? card.iconSource : Icons.getIcon("notification")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    sourceSize.width: 80
                    sourceSize.height: 80
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.maximumWidth: 150
                        text: snap.appName
                        color: Colors.colors.foregroundSubtle
                        font.pixelSize: 11
                        font.family: Config.font
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: card.timeText.length > 0
                        text: "· " + card.timeText
                        color: Colors.colors.foregroundSubtle
                        font.pixelSize: 11
                        font.family: Config.font
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: closeHover.hovered ? Colors.colors.error : "transparent"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 11
                            font.family: Config.font
                            color: closeHover.hovered ? Colors.colors.background : Colors.colors.foregroundMuted
                        }

                        HoverHandler { id: closeHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.dismissed()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: snap.summary
                    textFormat: Text.PlainText
                    color: Colors.colors.foreground
                    font.pixelSize: 13
                    font.bold: true
                    font.family: Config.font
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: snap.body
                    textFormat: Text.StyledText
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 12
                    font.family: Config.font
                    wrapMode: Text.Wrap
                    maximumLineCount: card.expanded ? 50 : 3
                    elide: Text.ElideRight
                    linkColor: Colors.colors.link

                    onLinkActivated: link => {
                        if (/^https?:\/\//i.test(link))
                            Qt.openUrlExternally(link)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: card.buttonActions.length > 0
            spacing: 6

            Repeater {
                model: card.buttonActions

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: 8
                    color: actionHover.hovered ? Colors.colors.pressed : Colors.colors.surfaceAlt

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                        text: actionButton.modelData.text
                        color: Colors.colors.foreground
                        font.pixelSize: 11
                        font.family: Config.font
                        elide: Text.ElideRight
                    }

                    HoverHandler { id: actionHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.runAction(actionButton.modelData)
                    }
                }
            }
        }
    }

    // Countdown bar, drawn in the bottom padding.
    Rectangle {
        visible: card.toast && card.timeoutMs > 0
        x: 14
        y: card.height - 8
        width: (card.width - 28) * card.progress
        height: 2
        radius: 1
        color: card.critical ? Colors.colors.error : Colors.colors.accent
    }
}
