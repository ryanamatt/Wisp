// qml/CommandCenter/SettingsSection/SettingsComponents/SettingsOutline.qml

import QtQuick
import QtQuick.Controls
import "../../../Colors"
import "../../../Config"

// Vertical list of jump targets. `model` is an array of objects with a `name`.
ListView {
    id: root

    property int activeIndex: 0

    signal entryClicked(int index)

    clip: true
    spacing: 2
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds

    delegate: Rectangle {
        id: entry

        required property var modelData
        required property int index

        readonly property bool isActive: index === root.activeIndex

        width: ListView.view.width
        height: Math.max(28, label.implicitHeight + 12)
        radius: 6
        color: entryMouse.containsMouse ? Colors.colors.hover : "transparent"

        Rectangle {
            visible: entry.isActive
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height - 10
            radius: 2
            color: Colors.colors.accent
        }

        Text {
            id: label
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter

            text: entry.modelData.name
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            font.family: Config.font
            font.bold: entry.isActive
            color: entry.isActive ? Colors.colors.accent : Colors.colors.foregroundMuted
        }

        MouseArea {
            id: entryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.entryClicked(entry.index)
        }
    }
}
