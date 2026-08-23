// qml/CommandCenter/SystemSection/MetricGroupCard.qml

import QtQuick
import QtQuick.Layouts
import "../../Colors"

Rectangle {
    id: root

    property string title: ""
    default property alias content: contentRow.children

    Layout.fillWidth: true
    implicitHeight: innerColumn.implicitHeight + innerColumn.anchors.margins * 2

    color: Colors.colors.surface
    border.color: Colors.colors.border
    border.width: 1
    radius: 12

    ColumnLayout {
        id: innerColumn
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: root.title
            font.family: "Iosevka Nerd Font Propo"
            font.pixelSize: 14
            font.bold: true
            color: Colors.colors.accentAlt
        }

        RowLayout {
            id: contentRow
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 32
        }
    }
}
