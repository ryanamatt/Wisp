// qml/Runner/RunnerCalcPopup.qml

import QtQuick
import Quickshell
import "../Colors"
import "../Config"

PanelWindow {
    id: root

    // ---- Inputs ----
    // True while there is a solvable equation to show.
    property bool open: false
    property string expression: ""
    property real answer: 0

    // Geometry of the Runner this popup hangs from.
    property int runnerWidth: 400
    property int runnerHeight: 100
    property int runnerTopMargin: 0

    // ---- Tweakables ----
    property int popupHeight: 80
    property int bottomRadius: 30
    // How long an unsolvable equation is tolerated before closing. Stops the
    // popup from flickering while typing something like "5+" on the way to "5+3".
    property int closeDelay: 300

    readonly property int borderWidth: 2

    // ---- Animation state (read by Runner.qml) ----
    property real cornerProgress: 0
    property real slideProgress: 0

    // ---- Internals ----
    property bool expanded: false
    // Last good values. Kept while closing so the text does not change
    // or blank out while the card is sliding away.
    property string shownExpression: ""
    property string shownAnswer: ""

    function formatAnswer(v) {
        // Trim floating point noise (0.1 + 0.2 -> 0.3).
        return String(parseFloat(v.toPrecision(12)));
    }

    function sync() {
        if (!open) return;
        shownExpression = expression.trim() + " =";
        shownAnswer = formatAnswer(answer);
    }

    function setExpanded(value) {
        if (value === expanded) return;
        expanded = value;

        openAnim.stop();
        closeAnim.stop();

        // Scale durations by the distance left so interrupting is seamless.
        if (value) {
            openCorners.duration = Math.round(90 * (1 - cornerProgress));
            openSlide.duration = Math.round(280 * (1 - slideProgress));
            openAnim.start();
        } else {
            closeSlide.duration = Math.round(180 * slideProgress);
            closeCorners.duration = Math.round(90 * cornerProgress);
            closeAnim.start();
        }
    }

    // Jump straight to closed with no animation (used when the Runner hides).
    function snapClosed() {
        closeTimer.stop();
        openAnim.stop();
        closeAnim.stop();
        expanded = false;
        cornerProgress = 0;
        slideProgress = 0;
    }

    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            sync();
            setExpanded(true);
        } else {
            closeTimer.restart();
        }
    }
    onExpressionChanged: sync()
    onAnswerChanged: sync()

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: root.setExpanded(false)
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation {
            id: openCorners
            target: root; property: "cornerProgress"
            to: 1; duration: 90; easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            id: openSlide
            target: root; property: "slideProgress"
            to: 1; duration: 280; easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            id: closeSlide
            target: root; property: "slideProgress"
            to: 0; duration: 180; easing.type: Easing.InCubic
        }
        NumberAnimation {
            id: closeCorners
            target: root; property: "cornerProgress"
            to: 0; duration: 90; easing.type: Easing.InOutQuad
        }
    }

    // ---- Window ----
    visible: expanded || cornerProgress > 0 || slideProgress > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true }
    // Overlap the Runner by one border width so the two borders merge.
    margins.top: runnerTopMargin + runnerHeight - borderWidth

    implicitWidth: runnerWidth
    implicitHeight: popupHeight

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: card
            visible: root.slideProgress > 0

            width: parent.width
            // Extra border width on top, pushed above the clip edge, so only
            // the side and bottom borders are visible.
            height: root.popupHeight + root.borderWidth
            y: -root.borderWidth - (1 - root.slideProgress) * root.popupHeight

            color: Colors.colors.backgroundAlt
            border.color: Colors.colors.background
            border.width: root.borderWidth

            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: root.bottomRadius
            bottomRightRadius: root.bottomRadius

            Column {
                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 2

                // The equation, repeated back
                Text {
                    width: parent.width
                    text: root.shownExpression
                    color: Colors.colors.foregroundSubtle
                    font.pixelSize: 20
                    font.family: Config.font
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                // The answer
                Text {
                    id: answerText
                    width: parent.width
                    text: root.shownAnswer
                    color: Colors.colors.orange
                    font.pixelSize: 26
                    font.bold: true
                    font.family: Config.font
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    transformOrigin: Item.Center

                    // Small pop whenever the answer changes while visible.
                    onTextChanged: if (root.slideProgress > 0.99) bump.restart()

                    SequentialAnimation {
                        id: bump
                        NumberAnimation {
                            target: answerText; property: "scale"
                            to: 1.08; duration: 70; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: answerText; property: "scale"
                            to: 1.0; duration: 160; easing.type: Easing.OutBack
                        }
                    }
                }
            }
        }
    }
}
