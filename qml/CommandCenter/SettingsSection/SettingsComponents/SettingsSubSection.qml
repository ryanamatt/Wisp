// qml/CommandCenter/SettingsSection/SettingsComponents/SettingsSubSection.qml

import QtQuick
import QtQuick.Layouts
import "../../../Colors"
import "../../../Config"

ColumnLayout {
    id: root

    // Display name. Used for the heading, the outline entry and (later) search.
    property string name: ""

    // Lets SettingsSection discover sub sections for the outline automatically.
    readonly property bool isSubSection: true

    readonly property int padding: 16

    default property alias content: innerLayout.data

    Layout.fillWidth: true
    spacing: 0

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.name
        font.pixelSize: 20
        font.family: Config.font
        color: Colors.colors.accentAlt
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: innerLayout.implicitHeight + 2 * root.padding

        color: "transparent"
        border.color: Colors.colors.shadow
        border.width: 2

        ColumnLayout {
            id: innerLayout

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.padding

            spacing: 10
        }
    }
}
