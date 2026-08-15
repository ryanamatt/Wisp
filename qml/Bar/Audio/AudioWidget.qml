// qml/Bar/Audio/AudioWidget.qml

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Colors"
import "../../Components"

BarWidgetContainer {
    id: audioWidget

    property int barCount: 16
    property int maxRange: 7

    // Property holding the current bar values (raw ints, 0..maxRange)
    property var audioBars: []

    // Block characters used to render each amplitude level (index 0..7)
    readonly property var barChars: ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

    Process {
        id: cavaProcess

        command: [
            "bash", "-c",
            "cava -p <(cat <<'EOF'\n" +
            "[general]\n" +
            "bars = " + barCount + "\n" +
            "\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = " + maxRange + "\n" +
            "bar_delimiter = 59\n" +
            "frame_delimiter = 10\n" +
            "EOF\n" +
            ")"
        ]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                // Each line looks like: "3;5;1;7;0;4;2;6;5;3;" (trailing ';' possible)
                const values = data.split(";")
                    .filter(v => v.length > 0)
                    .map(v => parseInt(v, 10));

                if (values.length === 0)
                    return;

                audioWidget.audioBars = values;

                icon.text = values
                    .map(v => audioWidget.barChars[Math.max(0, Math.min(audioWidget.maxRange, v))])
                    .join("");
            }
        }

        onExited: (exitCode, exitStatus) => {
            icon.text = "cava error";
        }
    }

    icon.text: "…"
    icon.font.pixelSize: implicitWidth * 0.09

    icon.anchors.centerIn: undefined
    icon.anchors.horizontalCenter: audioWidget.horizontalCenter
    icon.anchors.bottom: audioWidget.bottom

    property bool popupOpen: false

    isOpenHere: popupOpen

    popupWindows: [audioPopupWindow]

    onRequestOpen: popupOpen = true
    onRequestClose: popupOpen = false

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.forceActiveFocus()
            activateFocusGrab()
        } else {
            releaseFocusGrab()
        }
    }

    PopupWindow {
        id: audioPopupWindow

        anchor.item: audioWidget
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitWidth: 320
        implicitHeight: 240

        visible: audioWidget.openProgress > 0.001 || audioWidget.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * audioWidget.openProgress
                opacity: audioWidget.openProgress
                y: (1 - audioWidget.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            audioWidget.open()
                        } else {
                            audioWidget.close()
                        }
                    }
                }

                AudioPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (audioWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: audioWidget.forceClose()
                }
            }
        }
    }
}
