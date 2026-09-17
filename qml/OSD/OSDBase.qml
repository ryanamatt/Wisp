// qml/OSD/OSDBase.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../Components"
import "../Colors"
import "../Config"

Scope {
    id: osdScope

    property bool whenVisible: false
    property string icon: ""
    property bool showBar: true
    property real barValue: 0
    property string valueText: ""

    property var targetScreen: {
        let focusedName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === focusedName)
                return Quickshell.screens[i];
        }
        return Quickshell.screens[0];
    }

    PanelWindow {
        id: osd
        screen: targetScreen

        visible: osdScope.whenVisible && targetScreen !== null

        anchors { bottom: true; left: true; right: true }
        margins.bottom: (osd.screen ? osd.screen.height : 1000) / 10
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
                    source: osdScope.icon
                    Layout.preferredWidth: rect.width * 0.15
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignCenter
                    fillMode: Image.PreserveAspectFit
                }

                UsageBar {
                    visible: osdScope.showBar
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    value: osdScope.barValue
                    barColor: Colors.colors.foregroundMuted
                    barFillColor: Colors.colors.accent
                }

                Text {
                    Layout.preferredWidth: rect.width / 3.5
                    Layout.alignment: Qt.AlignCenter
                    text: osdScope.valueText
                    color: Colors.colors.accent
                    font.pixelSize: width * 0.4
                    font.family: Config.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

        }

    }

}
