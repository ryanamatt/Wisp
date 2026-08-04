// qml/bar/AppLauncher/AppLauncher.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"
import "../../Components"

BarPopup {
    id: root

    signal requestClose()
    property int currentIndex: 0

    function resetSelection() {
        root.currentIndex = 0
    }

    // ----- App List -----

    property var appsModel: [
        {
            name: "Chrome",
            command: ["google-chrome-stable"],
            icon: "google-chrome",
            fallback: "\uf268" // chrome glyph
        },
        {
            name: "Discord",
            command: ["discord"],
            icon: "discord",
            fallback: "\uf392" // discord glyph
        },
        {
            name: "Spotify",
            command: ["spotify-launcher"],
            icon: "spotify-launcher",
            fallback: "\uf1bc" // spotify glyph
        },
        {
            name: "Obsidian",
            command: ["flatpak", "run", "md.obsidian.Obsidian"],
            icon: "md.obsidian.Obsidian",
            fallback: "\uf02d" // book glyph
        },
        {
            name: "VS Code",
            command: ["code"],
            icon: "vscode",
            fallback: "\ue70c" // vscode glyph
        },
        {
            name: "OBS Studio",
            command: ["flatpak", "run", "com.obsproject.Studio"],
            icon: "com.obsproject.Studio",
            fallback: "\uf03d" // video camera glyph
        },
        {
            name: "Steam",
            command: ["steam"],
            icon: "steam",
            fallback: "\uf1b6" // steam glyph
        },
        {
            name: "Dolphin",
            command: ["dolphin"],
            icon: "org.kde.dolphin",
            fallback: "\uf07c" // open folder glyph
        },
        {
            name: "Polychromatic",
            command: ["polychromatic-controller"],
            icon: "polychromatic",
            fallback: "\uf0eb" // lightbulb/RGB glyph
        }
    ]

    function launch(cmd) {
        launchProc.command = cmd
        launchProc.running = false
        launchProc.running = true
    }

    Process {
        id: launchProc
    }

    readonly property alias columns: appsFlow.columns

    function moveSelection(delta) {
        const count = root.appsModel.length
        if (count === 0) return
        root.currentIndex = Math.max(0, Math.min(count - 1, root.currentIndex + delta))
    }

    function launchSelected() {
        if (root.currentIndex >= 0 && root.currentIndex < root.appsModel.length) {
            root.launch(root.appsModel[root.currentIndex].command)
            root.requestClose()
        }
    }

    function ensureVisible(index) {
        const flick = scrollView.contentItem
        if (!flick || columns <= 0) return

        const tileHeight = 60
        const row = Math.floor(index / columns)
        const top = appsFlow.anchors.topMargin + row * (tileHeight + root.tileSpacing)
        const bottom = top + tileHeight

        if (top < flick.contentY) {
            flick.contentY = top
        } else if (bottom > flick.contentY + flick.height) {
            flick.contentY = bottom - flick.height
        }
    }

    onCurrentIndexChanged: ensureVisible(currentIndex)

    Keys.onLeftPressed:   moveSelection(-1)
    Keys.onRightPressed:  moveSelection(1)
    Keys.onUpPressed:     moveSelection(-columns)
    Keys.onDownPressed:   moveSelection(columns)
    Keys.onEscapePressed: root.requestClose()
    Keys.onReturnPressed: launchSelected()
    Keys.onEnterPressed:  launchSelected()

    property int tileWidth: 60
    property int tileSpacing: 12

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Item {
            width: root.width
            height: appsFlow.height

            Flow {
                id: appsFlow
                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter

                property int columns: Math.max(1, Math.floor((root.width + root.tileSpacing) / (root.tileWidth + root.tileSpacing)))

                width: columns * root.tileWidth + (columns - 1) * root.tileSpacing
                spacing: root.tileSpacing

                Repeater {
                    model: root.appsModel

                    delegate: Rectangle {
                        id: tile
                        width: root.tileWidth
                        height: 60
                        radius: 12

                        readonly property bool selected: index === root.currentIndex

                        color: (tileMouse.containsMouse || selected) ? Colors.colors.hover : Colors.colors.surface
                        border.color: (tileMouse.containsMouse || selected) ? Colors.colors.borderActive : Colors.colors.border
                        border.width: selected ? 2 : 1

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        scale: tileMouse.pressed ? 0.94 : ((tileMouse.containsMouse || selected) ? 1.05 : 1.0)
                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.currentIndex = index   // keep keyboard selection in sync with mouse
                            onClicked: {
                                root.launch(modelData.command)
                                root.requestClose()
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignHCenter

                                Image {
                                    id: iconImage
                                    anchors.fill: parent
                                    source: "image://icon/" + modelData.icon
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    fillMode: Image.PreserveAspectFit
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: iconImage.status !== Image.Ready
                                    text: modelData.fallback
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 22
                                    color: Colors.colors.foreground
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Colors.colors.foreground
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }
                        }
                    }
                }
            }
        }
    }
}