// qml/CommandCenter/PackagesSection/PackagesSection.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Colors"

ColumnLayout {
    id: root

    anchors.fill: parent
    clip: true
    spacing: 14

    // Adjust this if upkeep.sh lives somewhere else.
    property string upkeepScriptPath: Quickshell.env("WISP_SHARE_DIR") + "/scripts/upkeep.sh"

    property bool refreshing: false
    property string lastChecked: ""

    property int yayInstalledCount: 0
    property var yayUpdates: []

    property int flatpakInstalledCount: 0
    property var flatpakUpdates: []

    property int pendingChecks: 0

    function startCheck(proc) {
        pendingChecks += 1
        proc.running = true
    }

    function finishCheck() {
        pendingChecks = Math.max(0, pendingChecks - 1)
        if (pendingChecks === 0) {
            refreshing = false
            lastChecked = Qt.formatDateTime(new Date(), "hh:mm:ss")
        }
    }

    function nonEmptyLines(text) {
        return text.split(/\r?\n/).filter(line => line.trim().length > 0)
    }

    function refreshAll() {
        if (refreshing)
            return

        refreshing = true

        startCheck(yayTotalProc)
        startCheck(yayUpdatesProc)
        startCheck(flatpakTotalProc)
        startCheck(flatpakUpdatesProc)
    }

    function runUpkeep() {
        Quickshell.execDetached([
            "kitty", "-e", "sh", "-c",
            "sh " + root.upkeepScriptPath + "; echo; printf 'Done. Press enter to close...'; read _"
        ])
    }

    Process {
        id: yayTotalProc
        command: ["yay", "-Q"]
        stdout: StdioCollector {
            onStreamFinished: root.yayInstalledCount = root.nonEmptyLines(this.text).length
        }
        onExited: root.finishCheck()
    }

    Process {
        id: yayUpdatesProc
        command: ["yay", "-Qu"]
        stdout: StdioCollector {
            onStreamFinished: root.yayUpdates = root.nonEmptyLines(this.text)
        }
        onExited: root.finishCheck()
    }

    Process {
        id: flatpakTotalProc
        command: ["flatpak", "list", "--columns=application"]
        stdout: StdioCollector {
            onStreamFinished: root.flatpakInstalledCount = root.nonEmptyLines(this.text).length
        }
        onExited: root.finishCheck()
    }

    Process {
        id: flatpakUpdatesProc
        command: ["flatpak", "remote-ls", "--updates", "--columns=application"]
        stdout: StdioCollector {
            onStreamFinished: root.flatpakUpdates = root.nonEmptyLines(this.text)
        }
        onExited: root.finishCheck()
    }

    Component.onCompleted: refreshAll()

    // Header
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 10

        Text {
            text: "Packages"
            font.family: "Iosevka Nerd Font Propo"
            font.pixelSize: 20
            font.bold: true
            color: Colors.colors.accent
        }

        Item { Layout.fillWidth: true }

        Text {
            text: root.refreshing ? "Checking..." : (root.lastChecked.length ? "Checked " + root.lastChecked : "")
            font.family: "Iosevka Nerd Font Propo"
            font.pixelSize: 11
            color: Colors.colors.foregroundMuted
        }

        Rectangle {
            id: refreshButton
            implicitWidth: refreshText.implicitWidth + 20
            implicitHeight: 26
            radius: 8
            color: Colors.colors.surfaceAlt
            border.color: Colors.colors.border
            border.width: 1
            opacity: root.refreshing ? 0.6 : 1.0

            Text {
                id: refreshText
                anchors.centerIn: parent
                text: "Refresh"
                font.family: "Iosevka Nerd Font Propo"
                font.pixelSize: 12
                color: Colors.colors.accentAlt
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !root.refreshing
                onClicked: root.refreshAll()
            }
        }
    }

    // Stat cards
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: 10
            color: Colors.colors.surface
            border.color: Colors.colors.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Text {
                    text: "Arch / AUR"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 13
                    font.bold: true
                    color: Colors.colors.foreground
                }

                Text {
                    text: root.yayInstalledCount + " installed"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 11
                    color: Colors.colors.foregroundMuted
                }

                Text {
                    text: root.yayUpdates.length + (root.yayUpdates.length === 1 ? " update" : " updates")
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.yayUpdates.length > 0 ? Colors.colors.warning : Colors.colors.success
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: 10
            color: Colors.colors.surface
            border.color: Colors.colors.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Text {
                    text: "Flatpak"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 13
                    font.bold: true
                    color: Colors.colors.foreground
                }

                Text {
                    text: root.flatpakInstalledCount + " installed"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 11
                    color: Colors.colors.foregroundMuted
                }

                Text {
                    text: root.flatpakUpdates.length + (root.flatpakUpdates.length === 1 ? " update" : " updates")
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.flatpakUpdates.length > 0 ? Colors.colors.warning : Colors.colors.success
                }
            }
        }
    }

    // Pending update lists
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Colors.colors.backgroundAlt
            border.color: Colors.colors.border
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Text {
                    text: "Pending AUR / pacman"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 12
                    color: Colors.colors.foregroundMuted
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.yayUpdates
                    spacing: 2

                    delegate: Text {
                        width: ListView.view.width
                        text: modelData
                        font.family: "Iosevka Nerd Font Propo"
                        font.pixelSize: 11
                        color: Colors.colors.foreground
                        elide: Text.ElideRight
                    }
                }

                Text {
                    visible: !root.refreshing && root.yayUpdates.length === 0
                    text: "Up to date"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 11
                    color: Colors.colors.foregroundMuted
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Colors.colors.backgroundAlt
            border.color: Colors.colors.border
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Text {
                    text: "Pending Flatpak"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 12
                    color: Colors.colors.foregroundMuted
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.flatpakUpdates
                    spacing: 2

                    delegate: Text {
                        width: ListView.view.width
                        text: modelData
                        font.family: "Iosevka Nerd Font Propo"
                        font.pixelSize: 11
                        color: Colors.colors.foreground
                        elide: Text.ElideRight
                    }
                }

                Text {
                    visible: !root.refreshing && root.flatpakUpdates.length === 0
                    text: "Up to date"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 11
                    color: Colors.colors.foregroundMuted
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                }
            }
        }
    }

    // Action
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 10
        spacing: 10

        Rectangle {
            id: upkeepButton
            implicitWidth: upkeepText.implicitWidth + 28
            implicitHeight: 32
            radius: 8
            color: Colors.colors.accent

            Text {
                id: upkeepText
                anchors.centerIn: parent
                text: "Run Upkeep in Kitty"
                font.family: "Iosevka Nerd Font Propo"
                font.pixelSize: 12
                font.bold: true
                color: Colors.colors.background
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runUpkeep()
            }
        }

        Item { Layout.fillWidth: true }
    }
}
