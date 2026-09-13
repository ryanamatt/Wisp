// qml/CommandCenter/SystemSection/MetricGroupCard.qml

import QtQuick
import QtQuick.Layouts
import "../../Colors"
import "../../Config"

Rectangle {
    id: root

    property string title: ""
    default property alias content: contentRow.children

    Layout.fillWidth: true
    implicitHeight: innerColumn.implicitHeight + innerColumn.anchors.margins * 2

    color: Colors.colors.surface
    // border.color: Colors.colors.border
    // border.width: 1
    radius: 12

    ColumnLayout {
        id: innerColumn
        anchors.fill: parent
        anchors.margins: 16
        spacing: 2

        Text {
            text: root.title
            font.pixelSize: 20
            font.family: Config.font
            font.bold: true
            color: Colors.colors.accentAlt
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            id: contentRow
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 16
        }
    }
}
