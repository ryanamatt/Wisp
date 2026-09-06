// qml/Components/ToggleButton.qml

import QtQuick
import QtQuick.Layouts
import "../Colors"

RowLayout {
    id: rootLayout
    Layout.fillWidth: true
    spacing: 6
    Layout.alignment: Qt.AlignHCenter

    property bool condition: false
    property string label: "Save to Disk?"

    signal toggled(bool newValue)

    Rectangle {
        id: toggleSaveToDisk
        implicitWidth: 34
        implicitHeight: 18
        radius: height / 2
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
    }
}
