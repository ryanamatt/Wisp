// qml/CommandCenter/WelcomeSection/WelcomeSection.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Colors"
import "../../Effects"

ColumnLayout {
    id: root

    anchors.fill: parent
    clip: true
    spacing: 120

    property var userName: ""

    Process {
        id: getUser
        command: ["bash", "-c", "whoami"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const name = this.text.trim()
                userName = name.charAt(0).toUpperCase() + name.slice(1)
            }
        }
    }

    Component.onCompleted: {
        getUser.running = true
    }

    function greeting() {
        const hour = new Date().getHours()
        if (hour < 5) return "Burning the midnight oil"
        if (hour < 12) return "Good Morning"
        if (hour < 17) return "Good Afternoon"
        if (hour < 21) return "Good Evening"
        return "Good Night"
    }

    Text {
        id: greetingText
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        text: userName ? root.greeting() + ", " + userName + "!" : root.greeting()
        font.family: "Iosevka Nerd Font Propo"
        font.pixelSize: 25
        color: Colors.colors.foregroundMuted

        Timer {
            interval: 60000
            running: true
            repeat: true
            onTriggered: greetingText.text = root.greeting()
        }
    }

    Floating {
        id: mascotFloat
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        amplitude: 12
        duration: 2400
        tiltAngle: 2

        Image {
            id: mascot
            source: Quickshell.env("WISP_SHARE_DIR") + "/assets/wisp.svg"
            sourceSize.width: 256
            fillMode: Image.PreserveAspectFit
        }
    }

    Item {
        Layout.fillHeight: true
    }

}
