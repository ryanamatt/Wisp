// qml/Runner/RunnerCalcPopup.qml

import QtQuick
import "../Colors"
import "../Config"

RunnerBasePopup {
    id: root

    // ---- Inputs ----
    // `open` comes from the base. True while there is a solvable equation.
    property string expression: ""
    property real answer: 0

    // ---- Base settings ----
    popupHeight: 80
    openSlideDuration: 280
    closeSlideDuration: 180
    // How long an unsolvable equation is tolerated before closing. Stops the
    // popup from flickering while typing something like "5+" on the way to "5+3".
    closeDelay: 300
    // Free-form content, so no list padding.
    contentTopMargin: 0
    contentSideMargin: 0

    // ---- Internals ----
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

    onOpenChanged: sync()
    onExpressionChanged: sync()
    onAnswerChanged: sync()

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
