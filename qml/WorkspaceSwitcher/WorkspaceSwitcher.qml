// shell.qml

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "WorkspaceUtils.js" as WorkspaceUtils
import "../Colors"
import "../GlobalState"

PanelWindow {
    id: mainWindow

    // Each entry: { id, name, apps: [{ wmClass, title }] }
    property var workspaceModel: []

    // Holds the result of the "hyprctl -j workspaces" step until the
    // "hyprctl -j clients" step finishes and can merge the two.
    property var _parsedWorkspaces: []

    property int focusedIndex: -1

    property var selectedWorkspace: null

    // Resolves a window's WM_CLASS to something usable as an
    // IconImage.source, in order of confidence:
    //   1. exact / case-insensitive desktop-entry id match
    //   2. the manual override table (see WorkspaceUtils.classIconOverrides)
    //   3. a fuzzy scan through every known desktop entry
    //   4. a bare guess that the icon theme has a file named after the class
    function iconForClass(wmClass) {
        if (!wmClass || wmClass.length === 0) {
            return Quickshell.iconPath("application-x-executable", true)
        }

        const needle = wmClass.toLowerCase()
        let entry = DesktopEntries.byId(wmClass) || DesktopEntries.byId(needle)

        if (!entry) {
            const overrideId = WorkspaceUtils.classIconOverrides[needle]
            if (overrideId) entry = DesktopEntries.byId(overrideId)
        }

        if (!entry) {
            const apps = DesktopEntries.applications.values
            for (let i = 0; i < apps.length; i++) {
                const app = apps[i]
                const id = (app.id || "").toLowerCase()
                const name = (app.name || "").toLowerCase()
                if (id === needle || id.endsWith("." + needle) || name === needle) {
                    entry = app
                    break
                }
            }
        }

        if (entry && entry.icon) {
            return Quickshell.iconPath(entry.icon, "application-x-executable")
        }

        return Quickshell.iconPath(needle, "application-x-executable")
    }

    function moveFocus(delta) {
        const n = mainWindow.workspaceModel.length
        mainWindow.focusedIndex = ((mainWindow.focusedIndex + delta) % n + n) % n
    }

    Component.onCompleted: {
        getWorkspaces.running = true
    }

    // get the list of active workspaces.
    Process {
        id: getWorkspaces
        command: ["bash", "-c", "hyprctl -j workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                mainWindow._parsedWorkspaces = WorkspaceUtils.parseWorkspaces(this.text)
                getClients.running = true
            }
        }
    }

    // get every window so we know what's actually on each workspace.
    Process {
        id: getClients
        command: ["bash", "-c", "hyprctl -j clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                const grouped = WorkspaceUtils.groupClientsByWorkspace(this.text)
                mainWindow.workspaceModel = WorkspaceUtils.buildWorkspaceModel(mainWindow._parsedWorkspaces, grouped)
                getActiveWorkspace.running = true
            }
        }
    }

    // figure out which workspace was focused before we opened,
    // so the rolodex starts centered on it.
    Process {
        id: getActiveWorkspace
        command: ["bash", "-c", "hyprctl -j activeworkspace"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const active = JSON.parse(this.text)
                    const idx = WorkspaceUtils.indexOfWorkspaceId(mainWindow.workspaceModel, active.id)
                    if (idx !== -1) rolodexView.currentIndex = idx
                } catch (e) {
                    console.log("workspace switcher: couldn't read active workspace")
                }
            }
        }
    }

    Process {
        id: switchWorkspace
        command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.focus({ workspace = \"" + mainWindow.selectedWorkspace + "\" })'"]
        onExited: {
            GlobalState.workspaceSwitcher.close()
        }
    }

    anchors { top: true; bottom: true; left: true; right: true; }
    color: "transparent"

    visible: GlobalState.workspaceSwitcher.isOpen

    onVisibleChanged: {
        if (mainWindow.visible) {
            getWorkspaces.running = true
        }
    }

    focusable: true

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true

        // ----- Key Presses -----

        Keys.onEscapePressed: GlobalState.workspaceSwitcher.close()

        Keys.onUpPressed: { mainWindow.moveFocus(-1); rolodexView.currentIndex = mainWindow.focusedIndex }
        Keys.onDownPressed: { mainWindow.moveFocus(1); rolodexView.currentIndex = mainWindow.focusedIndex }

        Keys.onLeftPressed: { mainWindow.moveFocus(-1); rolodexView.currentIndex = mainWindow.focusedIndex }
        Keys.onRightPressed: { mainWindow.moveFocus(1); rolodexView.currentIndex = mainWindow.focusedIndex }

        Keys.onReturnPressed: {
            if (mainWindow.focusedIndex >= 0 && mainWindow.focusedIndex < mainWindow.workspaceModel.length) {
                const modelData = mainWindow.workspaceModel[mainWindow.focusedIndex]
                if (modelData.name && isNaN(Number(modelData.name))) {
                    mainWindow.selectedWorkspace = "name:" + modelData.name
                } else {
                    mainWindow.selectedWorkspace = modelData.id
                }
                switchWorkspace.running = true
            }
        }
        Keys.onEnterPressed: { scope.Keys.onReturnPressed(event) }
            

        // End Keys

        // Dim Surroundings
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.2) // Semi-transparent dark overlay

            Component.onCompleted: {
                opacity = 1.0
            }

            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    GlobalState.workspaceSwitcher.close()
                }
            }
        }

        // Actual Window
        Rectangle {
            id: winRect
            anchors.centerIn: parent
            implicitWidth: 200
            implicitHeight: 300
            radius: 50

            // Finaly Product will have Color be transparent but is this now for testing and visibility
            // color: Colors.colors.surface
            // border.color: Colors.colors.backgroundAlt
            // border.width: 4
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: {}
                onPressed: {}
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0) {
                        mainWindow.moveFocus(-1)
                    } else {
                        mainWindow.moveFocus(1)
                    }
                    rolodexView.currentIndex = mainWindow.focusedIndex
                }
            }

            Text {
                visible: mainWindow.workspaceModel.length === 0
                anchors.centerIn: parent
                text: "No active workspaces"
                color: Colors.colors.foregroundMuted
                font.pixelSize: 20
            }


            PathView {
                id: rolodexView
                visible: mainWindow.workspaceModel.length > 0
                anchors.fill: parent
                anchors.margins: 10

                model: mainWindow.workspaceModel
                pathItemCount: (mainWindow.workspaceModel && mainWindow.workspaceModel.length < 5) ? mainWindow.workspaceModel.length : 5

                highlightRangeMode: PathView.StrictlyEnforceRange
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5

                interactive: true

                onCurrentIndexChanged: {
                    mainWindow.focusedIndex = currentIndex
                }

                path: Path {
                    startX: rolodexView.width / 2
                    startY: 0
                    PathAttribute { name: "itemScale"; value: 0.75 }
                    PathAttribute { name: "itemOpacity"; value: 0.3 }

                    PathLine {
                        x: rolodexView.width / 2
                        y: rolodexView.height / 2
                    }
                    PathAttribute { name: "itemScale"; value: 1.0 }
                    PathAttribute { name: "itemOpacity"; value: 1.0 }

                    PathLine {
                        x: rolodexView.width / 2
                        y: rolodexView.height
                    }
                    PathAttribute { name: "itemScale"; value: 0.75 }
                    PathAttribute { name: "itemOpacity"; value: 0.3 }
                }

                delegate: Item {
                    id: delegateItem
                    width: winRect.width - 40
                    height: 50

                    property real itemProgress: PathView.percent !== undefined ? PathView.percent : 0.5

                    scale: PathView.itemScale !== undefined ? PathView.itemScale : 1.0
                    opacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 1.0

                    transform: Rotation {
                        origin.x: delegateItem.width / 2
                        origin.y: delegateItem.height / 2
                        axis { x: 1; y: 0; z: 0 }
                        angle: (1-0 - (delegateItem.scale)) * 45 * (PathView.percent < 0.5 ? 1 : -1)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        clip: true
                        color: Colors.colors.backgroundAlt
                        border.color: rolodexView.currentIndex === index ? Colors.colors.accent : Colors.colors.borderSoft
                        border.width: 2

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            // Left spacer to push content toward the middle
                            Item { Layout.fillWidth: true }

                            Text {
                                text: {
                                    if (modelData.name === "desktop") return "~:"
                                    if (modelData.name === "discord") return "D:"
                                    if (modelData.name === "spotify") return "S:"
                                    return modelData.id + ":"
                                }
                                color: Colors.colors.info
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Row {
                                spacing: 6

                                Repeater {
                                    model: modelData.apps

                                    IconImage {
                                        implicitSize: 28
                                        asynchronous: true
                                        source: mainWindow.iconForClass(modelData.wmClass)
                                    }
                                }
                            }

                            Text {
                                visible: modelData.apps.length === 0
                                text: "(empty)"
                                color: Colors.colors.foregroundMuted
                                font.pixelSize: 14
                                font.italic: true
                            }

                            // Right spacer to push content toward the middle
                            Item { Layout.fillWidth: true }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                rolodexView.currentIndex = index
                                if (modelData.name && isNaN(Number(modelData.name))) {
                                    mainWindow.selectedWorkspace = "name:" + modelData.name
                                } else {
                                    mainWindow.selectedWorkspace = modelData.id
                                }
                                switchWorkspace.running = true
                            }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }


                    }

                }


            }

        }


    }
}
