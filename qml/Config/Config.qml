// qml/Config/Config.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Wisp.Time

Singleton {
    id: config

    function envBool(name, fallback) {
        const v = Quickshell.env(name)
        if (v === "true" || v === "1") return true
        if (v === "false" || v === "0") return false
        return fallback
    }

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

    property bool packagesNotifyOnStartUp: envBool("WISP_PACKAGES_NOTIFY_ON_STARTUP", false)
    property bool pendingPackagesNotifyOnStartUp: packagesNotifyOnStartUp

    property bool packagesNotifyEveryDay: envBool("WISP_PACKAGES_NOTIFY_EVERY_DAY", false)
    property bool pendingPackagesNotifyEveryDay: packagesNotifyEveryDay

    // True whenever a staged setting differs from what's currently live.
    readonly property bool dirty: pendingTimeFormat !== timeFormat ||
                                  pendingBarOrientation !== barOrientation ||
                                  pendingWallpaperDirectory !== wallpaperDirectory ||
                                  pendingFont !== font ||
                                  pendingPackagesNotifyOnStartUp !== packagesNotifyOnStartUp ||
                                  pendingPackagesNotifyEveryDay !== packagesNotifyEveryDay

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

    function stagePackagesNotifyOnStartUp(enabled) {
        pendingPackagesNotifyOnStartUp = enabled
    }

    function stagePackagesNotifyEveryDay(enabled) {
        pendingPackagesNotifyEveryDay = enabled
    }

    function discardChanges() {
        pendingTimeFormat = timeFormat
        pendingBarOrientation = barOrientation
        pendingWallpaperDirectory = wallpaperDirectory
        pendingFont = font
        pendingPackagesNotifyOnStartUp = packagesNotifyOnStartUp
        pendingPackagesNotifyEveryDay = packagesNotifyEveryDay
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
        packagesNotifyOnStartUp = pendingPackagesNotifyOnStartUp
        packagesNotifyEveryDay = pendingPackagesNotifyEveryDay

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

            if (!parsed.packages || typeof parsed.packages !== "object") parsed.packages = {}
            parsed.packages.notifyOnStartUp = packagesNotifyOnStartUp
            parsed.packages.notifyEveryDay = packagesNotifyEveryDay

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
