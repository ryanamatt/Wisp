// qml/CommandCenter/WelcomeSection.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Colors"

ColumnLayout {
    id: root

    anchors.fill: parent
    clip: true
    spacing: 20

    property var userName: ""

    Process {
        id: getUser
        command: ["bash", "-c", "whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const name = this.text.trim()
                userName = name.charAt(0).toUpperCase() + name.slice(1)
            }
        }
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

    Image {
        id: mascot
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        source: Quickshell.env("WISP_SHARE_DIR") + "/assets/wisp.svg"
        sourceSize.width: 256
        fillMode: Image.PreserveAspectFit
    }

    Item {
        Layout.fillHeight: true
    }

}
