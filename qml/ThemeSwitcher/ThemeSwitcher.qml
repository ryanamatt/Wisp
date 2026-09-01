// qml/ThemeSwitcher/ThemeSwitcher.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../GlobalState"

PanelWindow {
    id: window

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"

    property var wallpapers: []
    property int focusedIndex: 0

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: true

    // Starts closed by default, opens only when IPC command triggers it
    visible: GlobalState.themeSwitcher.isOpen

    // Process to run the wallpaper change script
    Process {
        id: wallpaperProcess
        command: []
    }

    Process {
        id: listWallpapersProcess
        command: ["bash", "-c", "find " + window.wallpaperDir + " -maxdepth 1 -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' -o -name '*.gif' \\) | sort"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "") {
                    window.wallpapers.push(data.trim())
                    wallpaperModel.append({ filePath: data.trim() })
                }
            }
        }
        onStarted: {
            window.wallpapers = []
            wallpaperModel.clear()
        }
        onExited: (exitCode) => {
            wallpaperModel.append({ filePath: "", isRandom: true })
        }
    }

    ListModel {
        id: wallpaperModel
    }

    onVisibleChanged: {
        if (visible) {
            listWallpapersProcess.running = true
            focusedIndex = 0
            focusScope.forceActiveFocus()
        }
    }

    FocusScope {
        id: focusScope 
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: GlobalState.themeSwitcher.close()

        Keys.onReturnPressed: {
            confirmSelection()
        }
        Keys.onEnterPressed: {
            confirmSelection()
        }

        function confirmSelection() {
            if (wallpaperModel.count > 0 && focusedIndex >= 0 && focusedIndex < wallpaperModel.count) {
                let entry = wallpaperModel.get(focusedIndex)
                let path

                if (entry.isRandom) {
                    if (window.wallpapers.length === 0) return
                    let randomIdx = Math.floor(Math.random() * window.wallpapers.length)
                    path = window.wallpapers[randomIdx]
                } else {
                    path = entry.filePath
                }

                let scriptPath = Quickshell.env("WISP_SHARE_DIR") + "/scripts/change_wallpaper.sh"
                wallpaperProcess.command = ["bash", scriptPath, path]
                wallpaperProcess.running = true
                GlobalState.themeSwitcher.close()
            }
        }

        // Dim Screen behind
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Colors.colors.surfaceAlt.r, Colors.colors.surfaceAlt.g, Colors.colors.surfaceAlt.b, 0.2)

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalState.themeSwitcher.close()
            }    
        }

        Rectangle {
            id: winRect 
            anchors.centerIn: parent
            width: Math.min(840, parent.width - 80)
            height: Math.min(360, parent.height - 80)
            radius: 14
            color: Colors.colors.background
            border.color: Colors.colors.border
            border.width: 2

            // Swallow clicks so the dim screen's MouseArea doesn't see them
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Text {
                    text: "Select Wallpaper"
                    color: Colors.colors.foreground
                    font.pixelSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // Horizontal Gallery View showing roughly 5 items at a time
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    model: wallpaperModel
                    spacing: 15
                    clip: true
                    focus: true

                    currentIndex: window.focusedIndex

                    Keys.onLeftPressed: {
                        if (count > 0) {
                            window.focusedIndex = (window.focusedIndex - 1 + count) % count
                            listView.positionViewAtIndex(window.focusedIndex, ListView.Contain)
                        }
                    }
                    Keys.onRightPressed: {
                        if (count > 0) {
                            window.focusedIndex = (window.focusedIndex + 1) % count
                            listView.positionViewAtIndex(window.focusedIndex, ListView.Contain)
                        }
                    }

                    // Allow mouse wheel scrolling and clicking items directly
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        width: 130
                        height: listView.height

                        readonly property bool isFocused: index === window.focusedIndex

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Colors.colors.surface
                            border.color: isFocused ? Colors.colors.accent : Colors.colors.borderSoft
                            border.width: isFocused ? 3 : 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: filePath ? "file://" + filePath : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                visible: !isRandom
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                visible: isRandom === true

                                Text {
                                    text: "🎲"
                                    font.pixelSize: 32
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Random"
                                    color: Colors.colors.foreground
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    window.focusedIndex = index
                                    focusScope.confirmSelection()
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "Use ← / → arrows to navigate (wraps around), Enter to confirm, Esc to close"
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
