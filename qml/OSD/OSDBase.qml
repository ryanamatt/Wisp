// qml/OSD/OSD.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Components"
import "../Colors"
import "../Config"

Variants {
    model: Quickshell.screens

    property bool whenVisible: false
    property string icon: ""
    property real barValue: 0
    property string valueText: ""

    PanelWindow {
        id: osd
        required property var modelData
        screen: modelData

        visible: whenVisible

        anchors { bottom: true; left: true; right: true }
        margins.bottom: osd.screen.height / 10
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore 

        Rectangle {
            id: rect
            anchors.centerIn: parent

            implicitWidth: 150
            implicitHeight: 40

            radius: rect.width / 5

            color: Colors.colors.backgroundAlt
            border.color: Colors.colors.background
            border.width: 2

            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 2

                Image {
                    id: iconImage
                    source: icon
                    Layout.preferredWidth: rect.width * 0.15
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignCenter
                    fillMode: Image.PreserveAspectFit
                }

                UsageBar {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    value: barValue
                    barColor: Colors.colors.foregroundMuted
                    barFillColor: Colors.colors.accent
                }

                Text {
                    Layout.alignment: Qt.AlignCenter
                    text: valueText
                    color: Colors.colors.accent
                    font.pixelSize: width * 0.5
                    font.family: Config.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

        }

    }

}
