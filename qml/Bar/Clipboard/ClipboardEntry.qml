// qml/Bar/Clipboard/ClipboardEntry.qml

import QtQuick
import QtQuick.Layouts
import "../../Components"
import "../../Colors"
import "../../Config"

// One clipboard row. Used by both the Pinned and History lists so the
// pin and delete buttons are laid out identically in each.
Rectangle {
    id: root

    // The raw "<id>\t<preview>" line from cliphist.
    property string line: ""
    property bool pinned: false

    // Emitted when the row body is clicked (copy + close is up to the popup).
    signal activated()

    readonly property string previewText: root.line.replace(/^\d+\t/, "")
    readonly property bool isImage: /^\[\[\s*binary data/i.test(root.previewText)
    property string imagePath: ""

    // Friendly label for image entries, e.g. "1.2 MiB · 1920x1080 · png"
    readonly property string imageLabel: {
        const m = root.previewText.match(/binary data\s*([^,\]]+)(?:,\s*(\d+x\d+))?(?:,\s*([a-zA-Z0-9]+))?/i)
        if (!m)
            return root.previewText
        return [m[1] ? m[1].trim() : "", m[2], m[3]].filter(Boolean).join(" · ")
    }

    height: root.isImage ? 52 : 35
    radius: 6
    color: itemHover.hovered ? Colors.colors.hover : Colors.colors.surface

    Behavior on color { ColorAnimation { duration: 100 } }

    HoverHandler { id: itemHover }

    Component.onCompleted: {
        if (root.isImage) {
            ClipboardSingleton.decodeToFile(root.line, function(path) {
                if (root)
                    root.imagePath = path
            })
        }
    }

    // Declared BEFORE the row so it sits underneath it. The buttons on top
    // handle their own clicks, so no manual rightMargin hack is needed.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 8

        Rectangle {
            visible: root.isImage
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter
            radius: 4
            color: Colors.colors.surfaceAlt
            clip: true

            Image {
                anchors.fill: parent
                visible: root.imagePath.length > 0
                source: root.imagePath.length > 0 ? ("file://" + root.imagePath) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.isImage ? root.imageLabel : root.previewText
            color: Colors.colors.foreground
            font.family: Config.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        // Fixed-size action buttons. Previously their width was a fraction of
        // the row's implicitWidth, which changes with the text, so they drifted.
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            IconButton {
                icon: "ui/pin"
                iconSize: 14
                implicitWidth: 24
                implicitHeight: 24
                tint: root.pinned ? Colors.colors.accent : Colors.colors.foregroundMuted
                hoverColor: Colors.colors.accentAlt
                tintOnHover: Colors.colors.background

                onClicked: ClipboardSingleton.togglePin(root.line)
            }

            IconButton {
                icon: "ui/close"
                iconSize: 14
                implicitWidth: 24
                implicitHeight: 24
                tint: Colors.colors.foregroundMuted
                hoverColor: Colors.colors.error
                tintOnHover: Colors.colors.background

                onClicked: ClipboardSingleton.deleteEntry(root.line)
            }
        }
    }
}
