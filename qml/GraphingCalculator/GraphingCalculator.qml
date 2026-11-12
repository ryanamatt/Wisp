// qml/GraphingCalculator/GraphingCalculator.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import "../Colors"
import "../IpcState"
import "../Config"

FloatingWindow {
    id: win

    title: "Wisp Graphing Calculator"

    implicitWidth: 980
    implicitHeight: 640
    minimumSize: Qt.size(640, 420)

    color: "transparent"

    visible: IpcState.graphingCalculator.isOpen

    readonly property string viewText: {
        "x: 0, y: 0"
    }

    onVisibleChanged: {
        if (visible) {
            focusScope.forceActiveFocus();
        } else if (IpcState.graphingCalculator.isOpen) {
            IpcState.graphingCalculator.close()
        }
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: IpcState.graphingCalculator.close()

        Rectangle {
            id: winRect

            anchors.fill: parent
            radius: 14
            color: Colors.colors.background
            border.color: Colors.colors.border
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                GraphHeader {
                    Layout.fillWidth: true
                    win: win
                    subtitle: win.viewText
                    onCloseRequested: IpcState.graphingCalculator.close()
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    ExpressionPanel {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 300
                        Layout.fillHeight: true
                        graph: canvas.graph
                    }

                    GraphCanvas {
                        id: canvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                }
            }
        }
    }
}

