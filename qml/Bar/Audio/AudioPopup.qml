// qml/Bar/Audio/AudioPopup.qml

import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../Colors"
import "../../Components"
import "../../Config"
import "../../Icons"
import "../../Utils/Utils.js" as Utils
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

            AnimatedIconButton {
                nudge: 0
                pulseColor: Colors.colors.accentAlt
                source: audioPopup.micMuted
                    ? Icons.getIcon("audio/micOff")
                    : Icons.getIcon("audio/mic")

                Layout.preferredWidth: micLayout.width * 0.075
                Layout.preferredHeight: width

                enabled: true
                onClicked: audioPopup.toggleMicMute()
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

            AnimatedIconButton {
                nudge: 0
                pulseColor: Colors.colors.accentAlt
                source: {
                    if (audioPopup.muted || audioPopup.volume === 0)
                        return Icons.getIcon("audio/volumeOff")
                    if (audioPopup.volume < 0.3)
                        return Icons.getIcon("audio/volumeDown")
                    return Icons.getIcon("audio/volumeUp")
                }

                Layout.preferredWidth: volLayout.width * 0.075
                Layout.preferredHeight: width

                enabled: true
                onClicked: audioPopup.toggleMute()
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
                        property bool verified: false
                        property int retries: 0

                        // Only ever hand this to Image once confirmed the file is actually there.
                        source: verified ? artUrl : Icons.getIcon("audio/album")
                        width: 64
                        height: width

                        sourceSize: Qt.size(width * Screen.devicePixelRatio,
                                            height * Screen.devicePixelRatio)
                        smooth: true
                        mipmap: true


                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready

                        onStatusChanged: {
                            if (status === Image.Error && retries < 3 && artUrl.toString() !== "") {
                                retries++
                                retryTimer.restart()
                            }
                        }

                        function checkArt() {
                            const url = artUrl.toString()
                            if (url === "")
                                return

                            if (url.indexOf("file://") !== 0) {
                                // Remote or embedded art has nothing to check on disk.
                                // Force a fresh load on retry.
                                verified = false
                                verified = true
                                return
                            }

                            existsCheck.command = ["test", "-e", url.substring(7)]
                            existsCheck.running = true
                        }

                        Process {
                            id: existsCheck
                            onExited: exitCode => {
                                if (exitCode === 0) {
                                    artImage.verified = true
                                } else if (artImage.retries < 10) {
                                    artImage.retries++
                                    retryTimer.restart()
                                }
                            }
                        }

                        Timer {
                            id: retryTimer
                            interval: 200
                            onTriggered: artImage.checkArt()
                        }
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: audioPopup.hasPlayer ? (audioPopup.activePlayer.trackTitle || "Unknown Title") : ""
                        textFormat: Text.PlainText
                        color: Colors.colors.foreground
                        font.family: Config.font
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: audioPopup.hasPlayer ? (audioPopup.activePlayer.trackArtist || "Unknown Artist") : ""
                        textFormat: Text.PlainText
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

                // Left Cell: elapsted time
                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    implicitHeight: elapsedText.implicitHeight

                    Text {
                        id: elapsedText
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: audioPopup.hasPlayer ? Utils.formatTime(audioPopup.activePlayer.position): "0:00"
                        textFormat: Text.PlainText
                        color: Colors.colors.foregroundMuted
                        font.family: Config.font
                        font.pixelSize: 10
                    }
                }

                AnimatedIconButton {
                    source: Icons.getIcon("audio/previous")
                    nudge: -1
                    pulseColor: Colors.colors.accentAlt

                    Layout.preferredWidth: volLayout.width * 0.1
                    Layout.preferredHeight: width

                    enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canGoPrevious
                    onClicked: audioPopup.activePlayer.previous()
                }

                AnimatedIconButton {
                    source: (audioPopup.hasPlayer && audioPopup.activePlayer.isPlaying)
                            ? Icons.getIcon("audio/pause")
                            : Icons.getIcon("audio/play")
                    animateSourceChange: true
                    pulseColor: Colors.colors.accentAlt

                    Layout.preferredWidth: volLayout.width * 0.1
                    Layout.preferredHeight: width

                    enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canTogglePlaying
                    onClicked: audioPopup.activePlayer.togglePlaying()
                }

                AnimatedIconButton {
                    source: Icons.getIcon("audio/next")
                    nudge: 1
                    pulseColor: Colors.colors.accentAlt

                    Layout.preferredWidth: volLayout.width * 0.1
                    Layout.preferredHeight: width

                    enabled: audioPopup.hasPlayer && audioPopup.activePlayer.canGoNext
                    onClicked: audioPopup.activePlayer.next()
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    implicitHeight: lengthText.implicitHeight

                    Text {
                        id: lengthText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: audioPopup.hasPlayer ? (audioPopup.activePlayerLength > 86400 ? ">24h": Utils.formatTime(audioPopup.activePlayer.length)) : "0:00"
                        textFormat: Text.PlainText
                        color: Colors.colors.foregroundMuted
                        font.family: Config.font
                        font.pixelSize: 10
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            visible: !audioPopup.hasPlayer
            text: "Nothing playing"
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            color: Colors.colors.foregroundMuted
            font.family: Config.font
            font.pixelSize: 12
        }
    }
}
