// qml/CommandCenter/SettingsSection/SettingsComponents/UnsavedIndicator.qml

import QtQuick
import QtQuick.Controls
import "../../../Colors"

// Small dot shown beside a setting whose staged value differs from the saved
// one. It always reserves its space, so rows never shift when it appears.
Item {
    id: root

    property bool active: false
    property string tip: "Unsaved change"

    readonly property int dotSize: 8

    implicitWidth: 14
    implicitHeight: 14

    Rectangle {
        id: dot
        anchors.centerIn: parent
        width: root.dotSize
        height: root.dotSize
        radius: width / 2
        color: Colors.colors.warning

        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.4

        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: root.active
    }

    ToolTip.visible: root.active && hoverArea.containsMouse
    ToolTip.text: root.tip
    ToolTip.delay: 300
}
