// qml/Bar/Notifications/NotificationsWidget.qml

import QtQuick
import Quickshell
import "../../Components"
import "../../IpcState"
import "../../Colors"
import "../../Config"
import "../../Icons"
import "../../Notifications"

BarWidgetContainer {
    id: notifWidget

    required property var screen

    iconImage.source: Icons.getIcon("ui/notification")
    iconImage.width: notifWidget.implicitWidth * 0.6
    iconImage.opacity: NotificationService.dnd ? 0.45 : 1

    isOpenHere: IpcState.notificationsWidget.isOpenOn(notifWidget.screen)

    popupWindows: [notifPopupWindow]

    onRequestOpen: IpcState.notificationsWidget.open(notifWidget.screen)
    onRequestClose: IpcState.notificationsWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            NotificationService.markAllRead()
            popup.forceActiveFocus()
            activateFocusGrab()
        } else {
            releaseFocusGrab()
        }
    }

    // Anything that arrives while the center is open is read immediately.
    Connections {
        target: NotificationService

        function onCountChanged() {
            if (notifWidget.isOpenHere)
                NotificationService.markAllRead()
        }
    }

    // Right click toggles Do Not Disturb. Left/hover handling stays with the
    // container's own MouseArea.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: NotificationService.dnd = !NotificationService.dnd
    }

    // Slash through the bell while Do Not Disturb is on.
    Rectangle {
        visible: NotificationService.dnd
        anchors.centerIn: parent
        width: 2
        height: notifWidget.implicitHeight * 0.6
        radius: 1
        rotation: 45
        color: Colors.colors.error
    }

    // Unread badge.
    Rectangle {
        visible: NotificationService.unreadCount > 0 && !notifWidget.isOpenHere && !NotificationService.dnd
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 2
        width: 14
        height: 14
        radius: 7
        color: Colors.colors.accent

        Text {
            anchors.centerIn: parent
            text: NotificationService.unreadCount > 9 ? "9+" : NotificationService.unreadCount
            color: Colors.colors.onAccent
            font.pixelSize: 9
            font.bold: true
            font.family: Config.font
        }
    }

    WidgetPopup {
        id: notifPopupWindow
        widget: notifWidget
        centered: false
        alignRight: true
        cornerRadius: 40
        implicitWidth: 360
        implicitHeight: 460

        NotificationsPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: notifWidget.forceClose()
        }
    }
}
