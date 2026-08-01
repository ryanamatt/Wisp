// qml/Colors/Colors.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dotfiles: home + "/dotfiles"

    property string currentTheme: ""

    // Fallback palette, used until the active theme's colors.json loads
    // (or if it's missing). Matches the shape every theme's
    // theme_colors.json should have.
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

    // Watches themes/.current_theme on disk. switcher.sh overwrites this
    // file on every switch; watchChanges makes Quickshell reload it
    // automatically (inotify), so currentTheme updates live with no
    // process restart and no signal from the bash script required.
    FileView {
        id: currentThemeFile
        path: root.dotfiles + "/themes/.current_theme"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const t = text().trim()
            if (t.length > 0 && t !== root.currentTheme) root.currentTheme = t
        }
        onLoadFailed: (error) => console.log("top-bar: no current theme file yet")
    }

    // Watches the active theme's colors.json. Its `path` is derived from
    // currentTheme, so it automatically re-points (and reloads) whenever
    // currentTheme changes above. watchChanges also picks up in-place
    // edits to the json for the currently active theme.
    FileView {
        id: colorsFile
        path: root.currentTheme.length > 0
            ? root.dotfiles + "/themes/" + root.currentTheme + "/quickshell/colors.json"
            : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                root.colors = Object.assign({}, root.colors, parsed)
            } catch (e) {
                console.log("top-bar: no valid colors.json for " + root.currentTheme)
            }
        }
        onLoadFailed: (error) => console.log("top-bar: couldn't load colors for " + root.currentTheme)
    }
}
