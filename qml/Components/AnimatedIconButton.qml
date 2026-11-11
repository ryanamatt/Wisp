// qml/Components/AnimatedIconButton.qml

import QtQuick

Item {
    id: root

    property url source

    // -1 nudges left on click, 1 nudges right, 0 disables the nudge.
    property int nudge: 0
    property real nudgeDistance: width * 0.2

    property real hoverScale: 1.12
    property real pressedScale: 0.82

    // Extra clickable area around the icon, in pixels.
    property real hitMargin: 6

    // Expanding ring on click.
    property bool pulse: true
    property color pulseColor: "#ffffff"

    // When true, a change of `source` plays a spin-and-pop on the new icon.
    property bool animateSourceChange: false
    property real swapRotation: 90

    property real disabledOpacity: 0.4
    property int cursorShape: Qt.PointingHandCursor

    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed

    signal clicked()

    // Plays the click animations without needing a real click.
    function playClickAnimation() {
        if (nudge !== 0)
            nudgeAnim.restart()
        if (pulse)
            pulseAnim.restart()
    }

    // ----- Internals -----
    property bool _ready: false
    Component.onCompleted: _ready = true

    onSourceChanged: {
        if (_ready && animateSourceChange)
            swapAnim.restart()
    }

    // Expanding ring, drawn behind the icon and not affected by press scaling.
    Rectangle {
        id: pulseRing
        anchors.centerIn: parent
        width: parent.width
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.pulseColor
        opacity: 0
        z: -1
    }

    // Holds hover / press scale, the nudge offset and the disabled fade.
    Item {
        id: visual
        width: root.width
        height: root.height

        opacity: root.enabled ? 1.0 : root.disabledOpacity
        scale: root.pressed ? root.pressedScale
             : root.hovered ? root.hoverScale
             : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: root.pressed ? 80 : 320
                easing.type: root.pressed ? Easing.OutQuad : Easing.OutBack
                easing.overshoot: 3.0
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Image {
            id: icon
            anchors.fill: parent
            source: root.source

            // Rendered a little larger than needed so hover scaling stays crisp.
            sourceSize.width: width * Screen.devicePixelRatio * Math.max(1, root.hoverScale)
            sourceSize.height: height * Screen.devicePixelRatio * Math.max(1, root.hoverScale)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -root.hitMargin
        hoverEnabled: true
        cursorShape: root.cursorShape

        onClicked: {
            root.playClickAnimation()
            root.clicked()
        }
    }

    // ----- Animations -----

    // Quick shove in the nudge direction, then an elastic return.
    SequentialAnimation {
        id: nudgeAnim
        NumberAnimation {
            target: visual
            property: "x"
            to: root.nudge * root.nudgeDistance
            duration: 70
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: visual
            property: "x"
            to: 0
            duration: 450
            easing.type: Easing.OutElastic
            easing.amplitude: 1.0
            easing.period: 0.4
        }
    }

    ParallelAnimation {
        id: pulseAnim
        NumberAnimation {
            target: pulseRing
            property: "scale"
            from: 0.7
            to: 1.8
            duration: 450
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: pulseRing
            property: "opacity"
            from: 0.6
            to: 0
            duration: 450
            easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: swapAnim
        NumberAnimation {
            target: icon
            property: "scale"
            from: 0.4
            to: 1.0
            duration: 340
            easing.type: Easing.OutBack
            easing.overshoot: 2.2
        }
        NumberAnimation {
            target: icon
            property: "rotation"
            from: -root.swapRotation
            to: 0
            duration: 340
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: icon
            property: "opacity"
            from: 0
            to: 1
            duration: 150
        }
    }
}
