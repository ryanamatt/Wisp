// qml/Bar/ThemeSwitcher/SwitcherPopup.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"
import "../../Components"

BarPopup {
    id: switcherPopup

    signal requestClose()

    function resetSelection() {

    }

    function closePopup() {

    }

    property var themeNames: []
    property var wallpaperNames: []
    property int selectedThemeIndex: -1
    property int selectedWallpaperIndex: -1
    property string selectedTheme: ""
    property string currentTheme: ""
    property string selectedWallpaper: ""
    property string currentWallpaper: ""

    // List theme directory names, e.g. ["Arcane", "Grotto", "Windward"]
    Process {
        id: listThemesProc
        running: true
        command: ["bash", "-c", "find '" + Quickshell.env("HOME") + "/dotfiles/themes' -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                switcherPopup.themeNames = this.text.split("\n").filter(s => s.length > 0)

                if (switcherPopup.themeNames.length > 0) {
                    var initialIndex = switcherPopup.themeNames.indexOf(switcherPopup.currentTheme)
                    switcherPopup.selectedThemeIndex = initialIndex !== -1 ? initialIndex : 0
                    
                    themeRolodex.currentIndex = switcherPopup.selectedThemeIndex

                    switcherPopup.selectedTheme = switcherPopup.themeNames[switcherPopup.selectedThemeIndex]
                    switcherPopup.refreshWallpapers()
                }
            }
        }
    }

    // Read themes/.current_theme (written by switcher.sh)
    Process {
        id: currentThemeProc
        running: true
        command: ["bash", "-c", "cat '" + Quickshell.env("HOME") + "/dotfiles/themes/.current_theme' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                switcherPopup.currentTheme = this.text.trim()
                listThemesProc.running = true
            }
        }
    }

    // Get a Themes Wallpapers
    Process {
        id: listWallpapers
        command: ["bash", "-c", "find '" + Quickshell.env("HOME") + "/dotfiles/wallpapers/" + selectedTheme + "' -mindepth 1 -maxdepth 1 -type f -printf '%f\\n' | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                switcherPopup.wallpaperNames = this.text.split("\n").filter(s => s.length > 0)
                switcherPopup.selectedWallpaperIndex = 0
            }
        }
    }

    // Central place to (re)load the wallpaper list for whatever selectedTheme
    // currently is.
    function refreshWallpapers() {
        if (switcherPopup.selectedTheme === "" || switcherPopup.selectedTheme === undefined) {
            return
        }
        if (listWallpapers.running) {
            listWallpapers.running = false
        }
        listWallpapers.running = true
    }

    Process {
        id: switchThemeProc
        command: ["bash", "-c", Quickshell.env("HOME") + "/dotfiles/switcher.sh " + selectedTheme]
    }

    function switchTheme() {
        selectedTheme = themeNames[selectedThemeIndex]
        switchThemeProc.running = true
        refreshWallpapers()
    }

    Process {
        id: switchWallpaperProc
        command: ["bash", "-c", Quickshell.env("HOME") + "/dotfiles/change_wallpaper.sh " + Quickshell.env("HOME") + "/dotfiles/wallpapers/" + selectedTheme + "/" + selectedWallpaper]
    }

    function switchWallpaper() {
        selectedWallpaper = wallpaperNames[selectedWallpaperIndex]
        switchWallpaperProc.running = true
    }

    Component.onCompleted: {
        currentThemeProc.running = true
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Rolodex Themes View
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: "transparent"
            clip: true

            PathView {
                id: themeRolodex
                anchors.fill: parent
                model: switcherPopup.themeNames
                pathItemCount: 7

                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange

                onCurrentIndexChanged: {
                    switcherPopup.selectedThemeIndex = currentIndex
                    if (switcherPopup.themeNames.length > 0) {
                        switcherPopup.selectedTheme = switcherPopup.themeNames[currentIndex]
                    }

                    switcherPopup.refreshWallpapers()
                }

                delegate: Item {
                    id: themeCard
                    required property var modelData
                    width: 180
                    height: 60

                    z: PathView.itemZ
                    scale: PathView.itemScale
                    opacity: PathView.itemOpacity

                    Rectangle {
                        anchors.fill: parent
                        color: themeCard.PathView.isCurrentItem ? Colors.colors.hover : Colors.colors.surfaceAlt
                        radius: 50
                        border.color: Colors.colors.border
                        border.width: themeCard.PathView.isCurrentItem ? 2 : 0

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 16
                            font.bold: themeCard.PathView.isCurrentItem
                            color: themeCard.PathView.isCurrentItem ? Colors.colors.foreground : Colors.colors.accentAlt
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            switcherPopup.selectedThemeIndex = switcherPopup.themeNames.indexOf(modelData)
                            switcherPopup.switchTheme()
                        }
                    }

                }

                path: Path {
                    startX: themeRolodex.width / 2
                    startY: -50

                    // Define layout attributes along the rolodex curve
                    PathAttribute { name: "itemZ"; value: 0 }
                    PathAttribute { name: "itemScale"; value: 0.7 }
                    PathAttribute { name: "itemOpacity"; value: 0.2 }

                    PathLine { x: themeRolodex.width / 2; y: themeRolodex.height / 2 }

                    PathAttribute { name: "itemZ"; value: 10 }
                    PathAttribute { name: "itemScale"; value: 1.0 }
                    PathAttribute { name: "itemOpacity"; value: 1.0 }

                    PathLine { x: themeRolodex.width / 2; y: themeRolodex.height + 50 }

                    PathAttribute { name: "itemZ"; value: 0 }
                    PathAttribute { name: "itemScale"; value: 0.7 }
                    PathAttribute { name: "itemOpacity"; value: 0.2 }
                }
            }
        }

        // Wallpapers
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: "transparent"
            clip: true

            Flickable {
                id: wallpaperFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: Math.max(contentColumn.implicitHeight, height)
                clip: true

                ColumnLayout {
                    id: contentColumn
                    width: wallpaperFlick.width
                    height: wallpaperFlick.contentHeight
                    spacing: 8
                    
                    // Top padding to give it breathing room similar to PathView
                    Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }

                    Repeater {
                        model: wallpaperNames

                        delegate: Item {
                            id: wallpaperCard
                            required property var modelData
                            required property int index
                            
                            width: contentColumn.width
                            height: 50

                            Rectangle {
                                width: 180
                                height: 50
                                anchors.horizontalCenter: parent.horizontalCenter
                                
                                color: index ? Colors.colors.hover : Colors.colors.surfaceAlt
                                radius: 25
                                border.color: Colors.colors.border
                                border.width: index ? 2 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 14
                                    color: index ? Colors.colors.foreground : Colors.colors.accentAlt
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    switcherPopup.selectedWallpaperIndex = index
                                    switcherPopup.switchWallpaper()
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
                }
            }

        }
    }
}