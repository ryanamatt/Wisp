// qml/CommandCenter/WelcomeSection.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../Colors"
import Wisp.Version

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

    Item {
        Layout.fillHeight: true
    }

    Text {
        id: versionText
        Layout.alignment: Qt.AlignRight
        Layout.rightMargin: 6
        Layout.bottomMargin: 4

        text: WispVersion.version
        font.family: "Iosevka Nerd Font Propo"
        font.pixelSize: 10
        color: Colors.colors.foregroundMuted
        opacity: 0.7
    }
}
