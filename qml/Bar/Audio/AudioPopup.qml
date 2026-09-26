// qml/Bar/Audio/AudioPopup.qml

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "../../Colors"
import "../../Components"
import "../../Config"
import "../../Icons"
import Wisp.Audio

BarPopup {
    id: audioPopup

    signal requestClose()

    Keys.onEscapePressed: audioPopup.requestClose()

    // ----- Audio: default sink volume / mute -----
    readonly property bool muted: Audio.sinkMuted
    readonly property real volume: Audio.sinkVolume

    function setVolume(v) {
        Audio.setSinkVolume(v)
    }

    function toggleMute() {
        Audio.toggleSinkMute()
    }

    // ----- Audio: default source (microphone) volume / mute -----
    readonly property bool micMuted: Audio.sourceMuted
    readonly property real micVolume: Audio.sourceVolume

    function setMicVolume(v) {
        Audio.setSourceVolume(v)
    }

    function toggleMicMute() {
        Audio.toggleSourceMute()
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
        if (activePlayer !== null && cachedPlayer !== activePlayer) {
            Qt.callLater(() => { cachedPlayer = activePlayer; })
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
        spacing: 10

        // ----- Microphone -----
        RowLayout {
            id: micLayout
            Layout.fillWidth: true
            spacing: 10

            Image {
                source: audioPopup.micMuted
                    ? Icons.getIcon("audio/micOff")
                    : Icons.getIcon("audio/mic")

                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio

                Layout.preferredWidth: micLayout.width * 0.075
                Layout.preferredHeight: width

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPopup.toggleMicMute()
                }
            }

            DragBar {
                Layout.fillWidth: true
                enabled: Audio.hasSource
                value: audioPopup.micMuted ? 0 : audioPopup.micVolume
                onMoved: v => audioPopup.setMicVolume(v)
            }

            Text {
                Layout.preferredWidth: 34
                text: Math.round(audioPopup.micVolume * 100) + "%"
                color: Colors.colors.foregroundMuted
                font.family: Config.font
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }

        // ----- Volume -----
        RowLayout {
            id: volLayout
            Layout.fillWidth: true
            spacing: 10

            Image {
                source: {
                    if (audioPopup.muted || audioPopup.volume === 0)
                        return Icons.getIcon("audio/volumeOff")
                    if (audioPopup.volume < 0.3)
                        return Icons.getIcon("audio/volumeDown")
                    return Icons.getIcon("audio/volumeUp")
                }

                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio

                Layout.preferredWidth: volLayout.width * 0.075
                Layout.preferredHeight: width

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPopup.toggleMute()
                }
            }

            DragBar {
                Layout.fillWidth: true
                enabled: Audio.hasSink
                value: audioPopup.muted ? 0 : audioPopup.volume
                onMoved: v => audioPopup.setVolume(v)
            }

            Text {
                Layout.preferredWidth: 34
                text: Math.round(audioPopup.volume * 100) + "%"
                color: Colors.colors.foregroundMuted
                font.family: Config.font
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
            id: playerLayout
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
                        id: artImage
                        anchors.fill: parent

                        readonly property url artUrl: audioPopup.hasPlayer ? audioPopup.activePlayer.trackArtUrl : ""
                        property int retries: 0
                        property bool reloading: false

                        // Toggling through "" forces a fresh request without breaking the binding
                        source: reloading ? "" : artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready

                        onArtUrlChanged: retries = 0

                        onStatusChanged: {
                            if (status === Image.Error && retries < 3 && artUrl.toString() !== "")
                                retryTimer.restart()
                        }

                        Timer {
                            id: retryTimer
                            interval: 1000
                            onTriggered: {
                                artImage.retries++
                                artImage.reloading = true
                                Qt.callLater(() => artImage.reloading = false)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: artImage.status !== Image.Ready
                        text: "Unknown"
                        font.family: Config.font
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
                        font.family: Config.font
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: audioPopup.hasPlayer ? (audioPopup.activePlayer.trackArtist || "Unknown Artist") : ""
                        color: Colors.colors.foregroundMuted
                        font.family: Config.font
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
                id: buttonLayout
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: audioPopup.hasPlayer ? audioPopup.formatTime(audioPopup.activePlayer.position) : "0:00"
                    color: Colors.colors.foregroundMuted
                    font.family: Config.font
                    font.pixelSize: 10
                }

                Item { Layout.fillWidth: true }

                Image {
                    source: Icons.getIcon("audio/previous")
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio

                    Layout.preferredWidth: volLayout.width * 0.1
                    Layout.preferredHeight: width

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canGoPrevious
                        onClicked: audioPopup.activePlayer.previous()
                    }
                }

                Image {
                    source: (audioPopup.hasPlayer && audioPopup.activePlayer.isPlaying) ? Icons.getIcon("audio/pause") : Icons.getIcon("audio/play")
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio

                    Layout.preferredWidth: volLayout.width * 0.1
                    Layout.preferredHeight: width

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canTogglePlaying
                        onClicked: audioPopup.activePlayer.togglePlaying()
                    }
                }

                Image {
                    source: Icons.getIcon("audio/next")
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio

                    Layout.preferredWidth: volLayout.width * 0.1
                    Layout.preferredHeight: width

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canGoNext
                        onClicked: audioPopup.activePlayer.next()
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: audioPopup.hasPlayer ? audioPopup.formatTime(audioPopup.activePlayer.length) : "0:00"
                    color: Colors.colors.foregroundMuted
                    font.family: Config.font
                    font.pixelSize: 10
                }
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
            font.family: Config.font
            font.pixelSize: 12
        }
    }
}
