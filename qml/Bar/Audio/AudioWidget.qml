// qml/Bar/Audio/AudioWidget.qml

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../Config"

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

                iconText.text = values
                    .map(v => audioWidget.barChars[Math.max(0, Math.min(audioWidget.maxRange, v))])
                    .join("");
            }
        }

        onExited: (exitCode, exitStatus) => {
            iconText.text = "cava error";
        }
    }

    // ----- Font-aware sizing -----
    // Glyph widths differ between fonts (and block characters often fall back
    // to a different font), so measure the full bar string at a reference size
    // and scale down so it always fits inside the widget.
    readonly property real measureSize: 100
    readonly property real sidePadding: 4

    TextMetrics {
        id: barMetrics
        font.family: Config.font
        font.pixelSize: audioWidget.measureSize
        text: "█".repeat(audioWidget.barCount)
    }

    FontMetrics {
        id: barFontMetrics
        font.family: Config.font
        font.pixelSize: audioWidget.measureSize
    }

    readonly property real maxSizeByWidth: barMetrics.advanceWidth > 0
        ? (width - 2 * (border.width + sidePadding)) * measureSize / barMetrics.advanceWidth
        : Number.POSITIVE_INFINITY

    readonly property real maxSizeByHeight: barFontMetrics.height > 0
        ? (height - 2 * border.width) * measureSize / barFontMetrics.height
        : Number.POSITIVE_INFINITY

    iconText.text: "…"
    iconText.font.pixelSize: Math.max(1, Math.floor(
        Math.min(implicitWidth * 0.09, maxSizeByWidth, maxSizeByHeight)))

    iconText.anchors.centerIn: undefined
    iconText.anchors.horizontalCenter: audioWidget.horizontalCenter
    iconText.anchors.bottom: audioWidget.bottom

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

    WidgetPopup {
        id: audioPopupWindow
        widget: audioWidget
        implicitWidth: 320
        implicitHeight: 245

        AudioPopup {
            id: popup
            anchors.fill: parent

            onRequestClose: audioWidget.forceClose()
        }
    }
}
