// qml/Runner/ModeBadge.qml
//
// Round badge that shows which Runner mode is active, with a little
// animation whenever the mode changes.

import QtQuick
import "../Colors"
import "../Config"

Rectangle {
    id: root

    // "none" | "command" | "calculator" | "symbol"
    property string mode: "none"

    // The mode currently drawn. It lags behind `mode` by half of the switch
    // animation so the glyph swaps while the badge is squashed.
    property string shownMode: mode

    readonly property color modeColor: {
        switch (shownMode) {
        case "command":    return Colors.colors.green;
        case "calculator": return Colors.colors.orange;
        case "symbol":     return Colors.colors.purple
        default:           return Colors.colors.foregroundSubtle;
        }
    }

    implicitWidth: 32
    implicitHeight: 32

    radius: width / 2
    color: Qt.alpha(modeColor, 0.18)
    border.width: 2
    border.color: modeColor

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // Squash, spin and pop whenever the mode changes.
    onModeChanged: switchAnim.restart()

    SequentialAnimation {
        id: switchAnim

        ParallelAnimation {
            NumberAnimation {
                target: root; property: "scale"
                to: 0.55; duration: 110; easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: glyphHolder; property: "rotation"
                to: 120; duration: 110; easing.type: Easing.InQuad
            }
        }

        ScriptAction {
            script: {
                root.shownMode = root.mode
                glyphHolder.rotation = -120
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root; property: "scale"
                to: 1.0; duration: 320; easing.type: Easing.OutBack
                easing.overshoot: 3
            }
            NumberAnimation {
                target: glyphHolder; property: "rotation"
                to: 0; duration: 320; easing.type: Easing.OutBack
            }
        }
    }

    Item {
        id: glyphHolder
        anchors.centerIn: parent
        width: parent.width
        height: parent.height

        // ---- None: a breathing wisp dot ----
        Rectangle {
            id: wispDot
            anchors.centerIn: parent
            visible: root.shownMode === "none"
            width: 8
            height: 8
            radius: 4
            color: root.modeColor

            SequentialAnimation {
                running: wispDot.visible
                loops: Animation.Infinite
                ParallelAnimation {
                    NumberAnimation { target: wispDot; property: "scale"; to: 1.6; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { target: wispDot; property: "opacity"; to: 0.5; duration: 900; easing.type: Easing.InOutSine }
                }
                ParallelAnimation {
                    NumberAnimation { target: wispDot; property: "scale"; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { target: wispDot; property: "opacity"; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                }
            }
        }

        // ---- Command: a prompt with a blinking cursor ----
        Row {
            id: promptRow
            anchors.centerIn: parent
            visible: root.shownMode === "command"
            spacing: 2

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ">"
                color: root.modeColor
                font.pixelSize: 14
                font.bold: true
                font.family: Config.font
            }

            Rectangle {
                id: cursorBar
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 4
                width: 6
                height: 2
                radius: 1
                color: root.modeColor

                SequentialAnimation {
                    running: promptRow.visible
                    loops: Animation.Infinite
                    NumberAnimation { target: cursorBar; property: "opacity"; to: 0.0; duration: 450; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: cursorBar; property: "opacity"; to: 1.0; duration: 450; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ---- Calculator: an equals sign that breathes ----
        Column {
            id: equalsBars
            anchors.centerIn: parent
            visible: root.shownMode === "calculator"
            spacing: 3

            Rectangle { width: 12; height: 2.5; radius: 1.25; color: root.modeColor }
            Rectangle { width: 12; height: 2.5; radius: 1.25; color: root.modeColor }

            SequentialAnimation {
                running: equalsBars.visible
                loops: Animation.Infinite
                NumberAnimation { target: equalsBars; property: "spacing"; to: 6; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { target: equalsBars; property: "spacing"; to: 3; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        // ---- Symbol & Emoji: a twinkling sparkle with an orbiting speck ----
        Item {
            id: symbolSparkle
            anchors.centerIn: parent
            visible: root.shownMode === "symbol"
            width: 20
            height: 20

            // The four-point star. Every 1.4s it twirls a quarter turn while
            // pinching in and popping back out, like a glint of light.
            Item {
                id: sparkleBody
                anchors.fill: parent

                Rectangle { anchors.centerIn: parent; width: 3; height: 16; radius: 1.5; color: root.modeColor }
                Rectangle { anchors.centerIn: parent; width: 16; height: 3; radius: 1.5; color: root.modeColor }
                Rectangle { anchors.centerIn: parent; width: 2; height: 10; radius: 1; rotation: 45; color: root.modeColor; opacity: 0.6 }
                Rectangle { anchors.centerIn: parent; width: 2; height: 10; radius: 1; rotation: -45; color: root.modeColor; opacity: 0.6 }
            }

            SequentialAnimation {
                running: symbolSparkle.visible
                loops: Animation.Infinite

                ParallelAnimation {
                    NumberAnimation {
                        target: sparkleBody; property: "rotation"
                        from: 0; to: 90; duration: 700; easing.type: Easing.InOutCubic
                    }
                    SequentialAnimation {
                        NumberAnimation { target: sparkleBody; property: "scale"; to: 0.65; duration: 350; easing.type: Easing.InQuad }
                        NumberAnimation { target: sparkleBody; property: "scale"; to: 1.0; duration: 350; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
                    }
                }
                PauseAnimation { duration: 700 }
            }

            // A tiny speck that circles the sparkle and twinkles as it goes.
            Item {
                id: orbit
                anchors.centerIn: parent
                width: 26
                height: 26

                Rectangle {
                    id: speck
                    x: (parent.width - width) / 2
                    y: 0
                    width: 3
                    height: 3
                    radius: 1.5
                    color: root.modeColor

                    SequentialAnimation {
                        running: symbolSparkle.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: speck; property: "opacity"; to: 0.25; duration: 400; easing.type: Easing.InOutSine }
                        NumberAnimation { target: speck; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.InOutSine }
                    }
                }

                NumberAnimation on rotation {
                    running: symbolSparkle.visible
                    from: 0; to: 360
                    duration: 2800
                    loops: Animation.Infinite
                }
            }
        }
    }
}
