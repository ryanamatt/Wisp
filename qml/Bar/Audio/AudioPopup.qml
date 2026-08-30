// qml/Bar/Audio/AudioPopup.qml

import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../../Colors"
import "../../Components"

BarPopup {
    id: audioPopup

    signal requestClose()

    Keys.onEscapePressed: audioPopup.requestClose()

    // ----- Pipewire: default sink volume / mute -----
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0

    // Binding the sink here is what actually keeps its audio properties live.
    PwObjectTracker {
        objects: audioPopup.sink ? [audioPopup.sink] : []
    }

    function setVolume(v) {
        if (sink && sink.ready && sink.audio) {
            sink.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function toggleMute() {
        if (sink && sink.ready && sink.audio) {
            sink.audio.muted = !sink.audio.muted
        }
    }

    // ----- MPRIS: pick whichever player is actually playing -----
    readonly property var playerList: Mpris.players.values
    property MprisPlayer cachedPlayer: null

    readonly property MprisPlayer activePlayer: {
        for (let i = 0; i < playerList.length; i++) {
            if (playerList[i].playbackState === MprisPlaybackState.Playing) {
                return playerList[i]
            }
        }
        
        if (cachedPlayer !== null && playerList.includes(cachedPlayer)) {
            return cachedPlayer
        }
        
        return playerList.length > 0 ? playerList[0] : null;
    }

    onActivePlayerChanged: {
        if (activePlayer !== null) {
            cachedPlayer = activePlayer;
        }
    }

    readonly property bool hasPlayer: activePlayer !== null

    function formatTime(seconds) {
        if (!seconds || seconds < 0 || !isFinite(seconds))
            return "0:00"
        const total = Math.floor(seconds)
        const m = Math.floor(total / 60)
        const s = total % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // Keep position advancing visually while playing, without hammering
    // dbus with a signal per frame.
    Timer {
        interval: 1000
        repeat: true
        running: audioPopup.hasPlayer
                 && audioPopup.activePlayer.playbackState === MprisPlaybackState.Playing
        onTriggered: audioPopup.activePlayer.positionChanged()
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 14

        // ----- Volume -----
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: audioPopup.muted ? "\ueee8"
                      : audioPopup.volume > 0.5 ? "\uf028"
                      : audioPopup.volume > 0 ? "\uf027" : "\uf026"
                font.family: "Iosevka Nerd Font Propo"
                font.pixelSize: 18
                color: audioPopup.muted ? Colors.colors.foregroundMuted : Colors.colors.foreground

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPopup.toggleMute()
                }
            }

            DragBar {
                Layout.fillWidth: true
                enabled: audioPopup.sink !== null
                value: audioPopup.muted ? 0 : audioPopup.volume
                onMoved: v => audioPopup.setVolume(v)
            }

            Text {
                Layout.preferredWidth: 34
                text: Math.round(audioPopup.volume * 100) + "%"
                color: Colors.colors.foregroundMuted
                font.family: "Noto Sans Mono"
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }

        // ----- MPRIS player -----
        ColumnLayout {
            Layout.fillWidth: true
            visible: audioPopup.hasPlayer
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 54
                    height: 54
                    radius: 8
                    color: Colors.colors.surface
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: audioPopup.hasPlayer ? audioPopup.activePlayer.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: source.toString() !== ""
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !audioPopup.hasPlayer || audioPopup.activePlayer.trackArtUrl === ""
                        text: "\uf001"
                        font.family: "Iosevka Nerd Font Propo"
                        font.pixelSize: 20
                        color: Colors.colors.foregroundMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: audioPopup.hasPlayer ? (audioPopup.activePlayer.trackTitle || "Unknown Title") : ""
                        color: Colors.colors.foreground
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: audioPopup.hasPlayer ? (audioPopup.activePlayer.trackArtist || "Unknown Artist") : ""
                        color: Colors.colors.foregroundMuted
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }

            DragBar {
                Layout.fillWidth: true
                enabled: audioPopup.hasPlayer
                         && audioPopup.activePlayer.canSeek
                         && audioPopup.activePlayer.positionSupported
                fillColor: Colors.colors.accentAlt
                value: (audioPopup.hasPlayer && audioPopup.activePlayer.length > 0)
                       ? audioPopup.activePlayer.position / audioPopup.activePlayer.length
                       : 0
                onMoved: v => {
                    if (audioPopup.hasPlayer)
                        audioPopup.activePlayer.position = v * audioPopup.activePlayer.length
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: audioPopup.hasPlayer ? audioPopup.formatTime(audioPopup.activePlayer.position) : "0:00"
                    color: Colors.colors.foregroundMuted
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 10
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: audioPopup.hasPlayer ? audioPopup.formatTime(audioPopup.activePlayer.length) : "0:00"
                    color: Colors.colors.foregroundMuted
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 10
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 20

                Item { Layout.fillWidth: true }

                Text {
                    text: "\uf048"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 16
                    color: (audioPopup.hasPlayer && audioPopup.activePlayer.canGoPrevious)
                           ? Colors.colors.foreground : Colors.colors.foregroundMuted

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canGoPrevious
                        onClicked: audioPopup.activePlayer.previous()
                    }
                }

                Text {
                    text: (audioPopup.hasPlayer && audioPopup.activePlayer.isPlaying) ? "\uf04c" : "\uf04b"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 20
                    color: Colors.colors.accent

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canTogglePlaying
                        onClicked: audioPopup.activePlayer.togglePlaying()
                    }
                }

                Text {
                    text: "\uf051"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 16
                    color: (audioPopup.hasPlayer && audioPopup.activePlayer.canGoNext)
                           ? Colors.colors.foreground : Colors.colors.foregroundMuted

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canGoNext
                        onClicked: audioPopup.activePlayer.next()
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            visible: !audioPopup.hasPlayer
            text: "Nothing playing"
            horizontalAlignment: Text.AlignHCenter
            color: Colors.colors.foregroundMuted
            font.family: "Noto Sans Mono"
            font.pixelSize: 12
        }
    }
}
