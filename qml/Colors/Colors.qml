// qml/Colors/Colors.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string config: home + "/.config/wisp"

    // Fallback palette
    property var colors: ({
        "background": "#0b151a",
        "backgroundAlt": "#172127",

        "surface": "#0b151a",
        "surfaceAlt": "#222b31",
        "surfaceElevated": "#313a41",
        "surfaceInput": "#131d22",
        "surfaceOverlay": "#2c363c",

        "foreground": "#dae4ec",
        "foregroundMuted": "#bec8d0",
        "foregroundSubtle": "#889299",
        "foregroundDisabled": "#3e484f",
        "onAccent": "#003549",

        "accent": "#78d1ff",
        "accentAlt": "#b3c6f9",
        "link": "#b0c9e7",

        "border": "#3e484f",
        "borderSoft": "#3e484f",
        "borderActive": "#78d1ff",
        "borderStrong": "#889299",
        "focusRing": "#78d1ff",

        "hover": "#2c363c",
        "pressed": "#314962",
        "selected": "#004c68",
        "focused": "#334671",
        "disabled": "#3e484f",
        "scrim": "#000000",

        "success": "#00e298",
        "warning": "#e1c700",
        "error": "#ffb4ab",
        "info": "#39d7ff",
        "neutral": "#3e484f",

        "purple": "#c8bfff",
        "blue": "#8fcdff",
        "cyan": "#3ad7ff",
        "teal": "#00dce5",
        "green": "#00e292",
        "lime": "#37e500",
        "yellow": "#d2cc00",
        "orange": "#ffba39",
        "red": "#ffb2bf",
        "pink": "#fface7",
        "magenta": "#e7b4ff",
        "indigo": "#aac7ff",

        "shadow": "#4078d1ff"
    })

    FileView {
        id: colorsFile
        path: root.config + "/colors.json"
            ? root.config + "/colors.json"
            : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                root.colors = Object.assign({}, root.colors, parsed)
            } catch (e) {}
        }
    }
}
