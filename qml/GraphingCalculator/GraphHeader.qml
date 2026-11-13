// qml/GraphingCalculator/GraphHeader.qml

import QtQuick
import QtQuick.Layouts
import "../Colors"
import "../Components"
import "../Config"

// Title Bar. Dragging it moves the window
Item {
    id: root

    // The Floating Window
    required property var win
    property string subtitle: ""

    signal closeRequested

    implicitHeight: row.implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: mouse => root.win.startSystemMove()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 10

        TintedIcon {
            name: "ui/function"
            tint: Colors.colors.accent
            implicitWidth: 24
            implicitHeight: 24
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "Graphing Calculator"
                color: Colors.colors.foreground
                font.pixelSize: 16
                font.family: Config.font
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: Colors.colors.foregroundSubtle
                font.pixelSize: 12
                font.family: Config.font
                elide: Text.ElideRight
            }
        }

        IconButton {
            icon: "ui/close"
            onClicked: root.closeRequested()
        }
    }
}

