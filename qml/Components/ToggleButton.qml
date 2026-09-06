// qml/Components/ToggleButton.qml

import QtQuick
import QtQuick.Layouts
import "../Colors"

Item {
    id: rootLayout
    Layout.fillWidth: true
    implicitHeight: contentRow.implicitHeight

    property bool condition: false
    property string label: ""

    signal toggled(bool newValue)

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            id: toggleSaveToDisk
            implicitWidth: 34
            implicitHeight: 18
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: rootLayout.condition ? Colors.colors.accent : Colors.colors.surfaceAlt
            border.width: 1
            border.color: rootLayout.condition ? Colors.colors.accent : Colors.colors.borderSoft

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: Colors.colors.foreground
                anchors.verticalCenter: parent.verticalCenter
                x: rootLayout.condition ? parent.width - width - 2 : 2

                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: rootLayout.toggled(!rootLayout.condition)
            }
        }

        Text {
            text: rootLayout.label
            color: Colors.colors.foregroundMuted
            font.pixelSize: 11
            font.family: "Noto Sans Mono"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
