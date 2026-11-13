// qml/GraphingCalculator/ExpressionPanel.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../Components"
import "../Config"

// Left Column: List of Expression and an Add Button
ColumnLayout {
    id: panel

    // The Graph to draw on
    required property var graph

    // Curve colors, as keys into Colors.colors. New rows take the first unused one.
    readonly property var palette: ["accent", "orange", "green", "pink", "purple", "teal", "yellow", "red"]

    // Set when the user adds a row so it takes focus (not for the starter row)
    property bool focusNewRow: false

    spacing: 10

    function nextColorKey() {
        const used = [];
        for (let i = 0; i < exprModel.count; i++)
            used.push(exprModel.get(i).colorKey);
        for (let j = 0; j < palette.length; j++) {
            if (used.indexOf(palette[j]) === -1)
                return palette[j];
        }
        return palette[exprModel.count % palette.length]
    }

    function addExpression(initial, focus) {
        panel.focusNewRow = focus;
        exprModel.append({
            "initial": initial,
            "colorKey": nextColorKey(),
            "shown": true
        })
    }

    function removeExpression(index) {
        exprModel.remove(index);
    }

        function cycleColor(index) {
        const current = palette.indexOf(exprModel.get(index).colorKey);
        exprModel.setProperty(index, "colorKey", palette[(current + 1) % palette.length]);
    }

    ListModel {
        id: exprModel
    }

    Component.onCompleted: addExpression("y = x + 2", false)

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Expressions"
            color: Colors.colors.foregroundMuted
            font.family: Config.font
            font.pixelSize: 13
            font.bold: true
        }

        IconButton {
            icon: "ui/add"
            tint: Colors.colors.accent
            onClicked: panel.addExpression("", true)
        }
    }

    Flickable {
        id: flick

        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: width
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: flick.contentHeight > flick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        ColumnLayout {
            id: list
            width: flick.width
            spacing: 8

            Repeater {
                id: rows
                model: exprModel

                delegate: ExpressionRow {
                    Layout.fillWidth: true
                    graph: panel.graph

                    onRemoveRequested: panel.removeExpression(index)
                    onColorCycleRequested: panel.cycleColor(index)
                    onVisibilityToggled: exprModel.setProperty(index, "shown", !shown)

                    onSubmitted: {
                        if (index === exprModel.count - 1)
                            panel.addExpression("", true);
                        else
                            rows.itemAt(index + 1).focusField();
                    }

                    onMoveFocus: delta => {
                        const target = rows.itemAt(index + delta);
                        if (target)
                            target.focusField();
                    }
                }

                onItemAdded: (index, item) => {
                    if (panel.focusNewRow) {
                        panel.focusNewRow = false;
                        item.focusField();
                    }
                }

            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 12
                visible: exprModel.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: "Add an expression to start graphing"
                color: Colors.colors.foregroundSubtle
                font.family: Config.font
                font.pixelSize: 12
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Drag to pan, scroll to zoom"
        color: Colors.colors.foregroundSubtle
        font.family: Config.font
        font.pixelSize: 11
    }

}

