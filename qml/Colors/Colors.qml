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
        background: "#0d0010",
        backgroundAlt: "#1a0028",
        surface: "#2a0e3a",
        surfaceAlt: "#3b1f4a",
        foreground: "#e8c5e9",
        foregroundMuted: "#a08bb0",
        accent: "#b00ea2",
        accentAlt: "#d966f5",
        border: "#2a0e3a",
        borderActive: "#b00ea2",
        borderSoft: "#443a52",
        borderStrong: "#5a4d6b",
        hover: "#3b1f4a",
        success: "#5ecfa0",
        warning: "#f5c842",
        error: "#e05c7a",
        info: "#9de8e8",
        shadow: "#40b00ea2"
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
