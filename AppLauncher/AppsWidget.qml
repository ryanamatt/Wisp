// AppLauncher/AppsWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../Colors"
import "../GlobalState"

Rectangle {
    id: appsWidget

    required property var screen

    color: Colors.colors.backgroundAlt
    border.color: Colors.colors.background
    border.width: 2

    implicitHeight: 36
    implicitWidth: 75

    // Full pill radius when closed, animates flat as the popup opens so the
    // bottom of the pill and the top of the popup read as one shape.
    readonly property real fullRadius: implicitHeight / 2
    topLeftRadius: fullRadius
    topRightRadius: fullRadius
    bottomLeftRadius: fullRadius * (1 - openProgress)
    bottomRightRadius: fullRadius * (1 - openProgress)

    // True only when THIS screen's launcher is the one that's open, since
    // AppsWidget is instantiated once per monitor but GlobalState is shared
    // across all of them.
    readonly property bool isOpenHere: GlobalState.isAppLauncherOpen
        && GlobalState.appLauncherScreen === appsWidget.screen

    // Drives the whole open/close animation. 0 = fully closed, 1 = fully open.
    property real openProgress: isOpenHere ? 1 : 0
    Behavior on openProgress {
        SpringAnimation { spring: 3.2; damping: 0.32; epsilon: 0.001 }
    }

    onIsOpenHereChanged: {
        if (isOpenHere) {
            launcher.resetSelection()
            launcher.forceActiveFocus()
            focusGrab.active = true
        } else {
            focusGrab.active = false
        }
    }

    Text {
        anchors.centerIn: parent
        text: "\uf40e"
        color: Colors.colors.foreground
        font.pixelSize: 25
        font.family: "Noto Sans Mono"
    }

    MouseArea {
        id: widgetHoverArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            hideTimer.stop()
            GlobalState.appLauncherScreen = appsWidget.screen
            GlobalState.isAppLauncherOpen = true
        }
        onExited: hideTimer.start()
    }

    Timer {
        id: hideTimer
        interval: 200
        onTriggered: {
            GlobalState.isAppLauncherOpen = false
            GlobalState.appLauncherScreen = null
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [launcherPopup]
        onCleared: {
            hideTimer.stop()
            GlobalState.isAppLauncherOpen = false
            GlobalState.appLauncherScreen = null
        }
    }

    PopupWindow {
        id: launcherPopup

        anchor.item: appsWidget
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 0

        color: "transparent"

        implicitWidth: 400
        implicitHeight: 300

        // Keep the window mapped while there's any animation left to show,
        // and drop it only once we've fully settled back to closed.
        visible: appsWidget.openProgress > 0.001 || appsWidget.isOpenHere

        Item {
            anchors.fill: parent

            // The panel grows out of the top-left corner (right where the
            // widget sits), scaling and sliding down into place with a
            // springy overshoot instead of a flat fade.
            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * appsWidget.openProgress
                opacity: appsWidget.openProgress
                y: (1 - appsWidget.openProgress) * -14

                // Only the top-left corner actually touches the pill above
                // it, so only that one squares off; every other corner
                // (including top-right) stays rounded like the rest of the
                // panel.
                topLeftRadius: 0
                topRightRadius: 40
                bottomLeftRadius: 40
                bottomRightRadius: 40

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            hideTimer.stop()
                            GlobalState.appLauncherScreen = appsWidget.screen
                            GlobalState.isAppLauncherOpen = true
                        } else {
                            hideTimer.start()
                        }
                    }
                }

                AppLauncher {
                    id: launcher
                    anchors.fill: parent
                    anchors.margins: 10
                    // Fade the contents in slightly after the panel itself,
                    // so the shape leads and the icons follow.
                    opacity: Math.max(0, (appsWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: {
                        hideTimer.stop()
                        GlobalState.isAppLauncherOpen = false
                        GlobalState.appLauncherScreen = null
                    }
                }

            }
        }
    }
    
}
