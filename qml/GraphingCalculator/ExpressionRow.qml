// qml/GraphingCalculator/ExpressionRow.qml

import QtQuick
import QtQuick.Layouts
import "../Colors"
import "../Components"
import "../Config"
import Wisp.Calculator

// One Expression: color swatch, text field, show/hide and delte.

Rectangle {
    id: row

    required property var graph

    required property int index
    required property string initial
    required property string colorKey
    required property bool shown

    signal removeRequested
    signal colorCycleRequested
    signal visibilityToggled
    signal submitted // Enter pressed
    signal moveFocus(int delta) // Up (-1), Down (+1)

    readonly property color lineColor: Colors.colors[colorKey] || Colors.colors.accent
    readonly property bool hasText: field.text.trim() !== ""
    readonly property bool hasError: hasText && fn.error !== ""

    function focusField() {
        field.forceActiveFocus();
        field.selectAll();
    }

    implicitHeight: content.implicitHeight + 16
    radius: 10
    color: Colors.colors.surfaceAlt
    border.width: 1.5
    border.color: field.activeFoucs ? Colors.colors.borderActive : row.hasError ? Colors.colors.error : "transparent"

    GraphFunction {
        id: fn
        text: field.text
        color: row.lineColor
        visible: row.shown
    }

    Component.onCompleted: {
        field.text = row.initial;
        row.graph.addFunction(fn);
    }

    Component.onDestruction: {
        if (row.graph)
        row.graph.removeFunction(fn);
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Click to Cycle the curve color
            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 11
                color: row.shown ? row.lineColor : "transparent"
                border.width: 2
                border.color: row.lineColor
                opacity: swatchArea.containsMouse ? 0.8 : 1.0

                MouseArea {
                    id: swatchArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.colorCycleRequested()
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text === ""
                    color: Colors.colors.foregroundSubtle
                    font.family: Config.font
                    font.pixelSize: 14
                }

                TextInput {
                    id: field
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    selectByMouse: true
                    color: Colors.colors.foreground
                    selectionColor: Colors.colors.accent
                    selectedTextColor: Colors.colors.onAccent
                    font.family: Config.font
                    font.pixelSize: 14
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                    Keys.onReturnPressed: row.submitted()
                    Keys.onEnterPressed: row.submitted()
                    Keys.onUpPressed: row.moveFocus(-1)
                    Keys.onDownPressed: row.moveFocus(1)
                }
            }

            IconButton {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                icon: row.shown ? "ui/visibility" : "ui/visibilityOff"
                iconSize: 16
                onClicked: row.visibilityToggled()
            }

            IconButton {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                icon: "ui/close"
                iconSize: 16
                onClicked: row.removeRequested()
            }
        }

        // Why the expression cannot be drawn
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 30
            visible: row.hasError
            text: fn.error
            color: Colors.colors.error
            font.family: Config.font
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }
}

