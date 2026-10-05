// qml/OSD/OSDManager.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../Components"
import "../Colors"
import "../Config"

Scope {
    id: root

    property int duration: 1000
    property bool whenVisible: false
    property var current: null

    property var targetScreen: {
        let focusedName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === focusedName)
                return Quickshell.screens[i];
        }
        return Quickshell.screens[0];
    }

    function show(source) {
        current = source
        whenVisible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: root.duration
        repeat: false
        onTriggered: root.whenVisible = false
    }

    // ---- Sources: add or remove OSDs here ----
    OSDBrightness { id: brightness; onRequested: root.show(brightness) }
    OSDVolume     { id: volume;     onRequested: root.show(volume) }
    OSDMic        { id: mic;        onRequested: root.show(mic) }
    OSDCapsLock   { id: capsLock;   onRequested: root.show(capsLock) }
    OSDNumLock    { id: numLock;    onRequested: root.show(numLock) }

    // ---- The single window ----
    PanelWindow {
        id: osd
        screen: root.targetScreen

        visible: root.whenVisible && root.current !== null && root.targetScreen !== null

        WlrLayershell.layer: WlrLayer.Overlay

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
                    source: root.current ? root.current.icon : ""
                    Layout.preferredWidth: rect.width * 0.15
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignCenter
                    fillMode: Image.PreserveAspectFit
                }

                UsageBar {
                    visible: root.current ? root.current.showBar : false
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    value: root.current ? root.current.barValue : 0
                    barColor: Colors.colors.foregroundMuted
                    barFillColor: Colors.colors.accent
                }

                Text {
                    Layout.preferredWidth: rect.width / 3.5
                    Layout.alignment: Qt.AlignCenter
                    text: root.current ? root.current.valueText : ""
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
