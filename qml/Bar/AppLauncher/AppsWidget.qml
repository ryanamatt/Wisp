// qml/bar/AppLauncher/AppsWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../../Colors"
import "../../Components"
import "../../GlobalState"

BarWidgetContainer {
    id: appsWidget

    required property var screen

    implicitWidth: 75

    icon.text: "\uf40e"

    // True only when THIS screen's launcher is the one that's open, since
    // AppsWidget is instantiated once per monitor but GlobalState is shared
    // across all of them.
    isOpenHere: GlobalState.isAppLauncherOpen
        && GlobalState.appLauncherScreen === appsWidget.screen

    popupWindows: [launcherPopup]

    onRequestOpen: {
        GlobalState.appLauncherScreen = appsWidget.screen
        GlobalState.isAppLauncherOpen = true
    }
    onRequestClose: {
        GlobalState.isAppLauncherOpen = false
        GlobalState.appLauncherScreen = null
    }

    onIsOpenHereChanged: {
        if (isOpenHere) {
            launcher.resetSelection()
            launcher.forceActiveFocus()
            activateFocusGrab()
        } else {
            releaseFocusGrab()
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
                            appsWidget.open()
                        } else {
                            appsWidget.close()
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

                    onRequestClose: appsWidget.forceClose()
                }

            }
        }
    }

}
