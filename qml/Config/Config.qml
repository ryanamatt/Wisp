// qml/Config/Config.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Wisp.Time

Singleton {
    id: config

    readonly property string home: Quickshell.env("HOME")
    readonly property string configPath: home + "/.config/wisp/config.json"

    property string timeFormat: Quickshell.env("WISP_TIME_FORMAT") || "ddd MMM d hh:mm:ss AP"
    property string pendingTimeFormat: timeFormat

    property string barOrientation: Quickshell.env("WISP_BAR_ORIENTATION") || "top"
    property string pendingBarOrientation: barOrientation

    property string wallpaperDirectory: Quickshell.env("WISP_WALLPAPER_DIR") || "~/Pictures/wallpapers"
    property string pendingWallpaperDirectory: wallpaperDirectory

    property string font: Quickshell.env("WISP_FONT") || "Noto Sans"
    property string pendingFont: font

    // True whenever a staged setting differs from what's currently live.
    readonly property bool dirty: pendingTimeFormat !== timeFormat ||
                                  pendingBarOrientation !== barOrientation ||
                                  pendingWallpaperDirectory !== wallpaperDirectory ||
                                  pendingFont !== font

    // Called by settings UI as the user picks a new value.
    function stageTimeFormat(format) {
        pendingTimeFormat = format
    }

    function stageBarOrientation(orientation) {
        pendingBarOrientation = orientation
    }

    function stageWallpaperDirectory(dir) {
        pendingWallpaperDirectory = dir
    }

    function stageFont(font) {
        pendingFont = font
    }

    function discardChanges() {
        pendingTimeFormat = timeFormat
        pendingBarOrientation = barOrientation
        pendingWallpaperDirectory = wallpaperDirectory
        pendingFont = font
    }

    // Applies every pending setting to the live bar and rewrites
    // config.json, leaving unrelated keys (font, wallpaper, apps...) as
    // they were.
    function save() {
        if (!dirty) return

        timeFormat = pendingTimeFormat
        Time.setFormatOverride(timeFormat)
        barOrientation = pendingBarOrientation
        wallpaperDirectory = pendingWallpaperDirectory
        font = pendingFont

        try {
            const raw = configFile.text()
            const parsed = raw.length > 0 ? JSON.parse(raw) : {}

            if (!parsed.bar || typeof parsed.bar !== "object") parsed.bar = {}
            parsed.bar.timeFormat = timeFormat
            parsed.bar.orientation = barOrientation

            if (!parsed.wallpaper || typeof parsed.wallpaper !== "object") parsed.wallpaper = {}
            parsed.wallpaper.directory = wallpaperDirectory

            if (!parsed.font) parsed.font = {}
            parsed.font = font

            configFile.setText(JSON.stringify(parsed, null, 4))
        } catch (e) {
            console.warn("Config: failed to save config.json:", e)
        }
    }

    FileView {
        id: configFile
        path: config.configPath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
}