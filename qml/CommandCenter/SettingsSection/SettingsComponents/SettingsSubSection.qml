// qml/CommandCenter/SettingsSection/SettingsComponents/SettingsSubSection.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../Colors"
import "../../../Config"
import "../../../Icons"

ColumnLayout {
    id: rootLayout
    spacing: 0

    property string sectionLabel: ""
    default property alias content: innerLayout.data

    Text {
        id: barSectionLabel
        Layout.alignment: Qt.AlignHCenter
        text: rootLayout.sectionLabel
        font.pixelSize: 20
        font.family: Config.font
        color: Colors.colors.accentAlt
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: innerLayout.implicitHeight + innerLayout.implicitHeight / 2
        Layout.leftMargin: rootLayout.width / 10
        Layout.rightMargin: Layout.leftMargin

        color: "transparent"
        border.color: Colors.colors.shadow
        border.width: 2

        ColumnLayout {
            id: innerLayout
            anchors.fill: parent
            Layout.fillWidth: true
            Layout.fillHeight: true
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 25

            spacing: 10

        }

    }
}

