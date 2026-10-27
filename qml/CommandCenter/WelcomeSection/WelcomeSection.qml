// qml/CommandCenter/WelcomeSection/WelcomeSection.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Colors"
import "../../Effects"
import "../../Config"
import "../../Icons"

ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: 30
    clip: true
    spacing: 120

    readonly property string userName: {
        const name = Quickshell.env("USER") || ""
        return name.charAt(0).toUpperCase() + name.slice(1)
    }

    property string greetingPrefix: greeting()

    function greeting() {
        const hour = new Date().getHours()
        if (hour < 5) return "Burning the midnight oil"
        if (hour < 12) return "Good Morning"
        if (hour < 17) return "Good Afternoon"
        if (hour < 21) return "Good Evening"
        return "Good Night"
    }

    property string currentJoke: ""

    function pickJoke(raw) {
        const jokes = raw.split("\n")
            .map(line => line.trim())
            .filter(line => line.length > 0)

        root.currentJoke = jokes.length > 0
            ? jokes[Math.floor(Math.random() * jokes.length)]
            : ""
    }

    FileView {
        id: jokeFile
        path: Config.jokesFilePath

        onLoaded: root.pickJoke(text())
        onLoadFailed: root.currentJoke = ""
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.greetingPrefix = root.greeting()
    }

    Text {
        id: greetingText
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        text: root.userName ? root.greetingPrefix + ", " + root.userName + "!" : root.greetingPrefix
        font.pixelSize: 25
        font.family: Config.font
        color: Colors.colors.foregroundMuted
    }

    FloatingEffect {
        id: mascotFloat
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        amplitude: 12
        duration: 2400
        tiltAngle: 2

        Image {
            id: mascot
            source: Icons.getMascot()
            sourceSize.width: 256
            fillMode: Image.PreserveAspectFit
        }
    }

    Text {
        id: jokeText
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.leftMargin: 30
        Layout.rightMargin: 30

        visible: root.currentJoke !== ""
        text: root.currentJoke
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 15
        font.italic: true
        font.family: Config.font
        color: Colors.colors.foregroundMuted
    }

    Item {
        Layout.fillHeight: true
    }

}
