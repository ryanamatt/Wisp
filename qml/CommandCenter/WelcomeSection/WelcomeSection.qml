// qml/CommandCenter/WelcomeSection/WelcomeSection.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Colors"
import "../../Effects"
import "../../Config"
import "../../Icons"

ColumnLayout {
    id: root

    anchors.fill: parent
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

    Item {
        Layout.fillHeight: true
    }

}
