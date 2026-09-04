// qml/Effects/FloatingEffect.qml

import QtQuick

Item {
    id: root

    default property alias data: content.data

    // Vertical drift, in px
    property real amplitude: 10
    // Horizontal drift, in px (0 disables)
    property real amplitudeX: 0
    // Time for one leg of the motion (up or down), in ms
    property int duration: 800
    // Slight tilt, in degrees (0 disables)
    property real tiltAngle: 0
    // Delay before starting, useful to desync multiple floating items
    property int startDelay: 0
    property bool running: true

    implicitWidth: content.implicitWidth + amplitudeX * 2
    implicitHeight: content.implicitHeight + amplitude * 2

    Item {
        id: content
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height

        transform: [
            Translate {
                id: floatTranslate
            },
            Rotation {
                id: floatRotation
                origin.x: content.width / 2
                origin.y: content.height / 2
            }
        ]

        SequentialAnimation {
            id: floatAnim
            running: root.running
            loops: Animation.Infinite

            PauseAnimation {
                duration: root.startDelay
            }

            ParallelAnimation {
                NumberAnimation {
                    target: floatTranslate
                    property: "y"
                    from: 0
                    to: -root.amplitude
                    duration: root.duration
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: floatTranslate
                    property: "x"
                    from: 0
                    to: root.amplitudeX
                    duration: root.duration
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: floatRotation
                    property: "angle"
                    from: 0
                    to: root.tiltAngle
                    duration: root.duration
                    easing.type: Easing.InOutSine
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: floatTranslate
                    property: "y"
                    from: -root.amplitude
                    to: 0
                    duration: root.duration
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: floatTranslate
                    property: "x"
                    from: root.amplitudeX
                    to: 0
                    duration: root.duration
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: floatRotation
                    property: "angle"
                    from: root.tiltAngle
                    to: 0
                    duration: root.duration
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
