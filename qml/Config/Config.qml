// qml/Config/Config.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Wisp.Battery
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

    // Expands a leading "~" (bare, or followed by "/") to $HOME. Anything
    // else, including "~otheruser/..." or a "~" mid-path, is left alone.
    function expandPath(path) {
        if (typeof path !== "string") return path
        if (path === "~") return home
        if (path.startsWith("~/")) return home + path.slice(1)
        return path
    }
    readonly property string xdgConfigHome: Quickshell.env("XDG_CONFIG_HOME")
    readonly property string configDir: xdgConfigHome ? xdgConfigHome + "/wisp" : home + "./config/wisp"
    readonly property string configPath: Quickshell.env("WISP_CONFIG_PATH")
        || configDir + "config.json"

    property string timeFormat: Quickshell.env("WISP_TIME_FORMAT") || "ddd MMM d hh:mm:ss AP"
    property string pendingTimeFormat: timeFormat

    property string barOrientation: Quickshell.env("WISP_BAR_ORIENTATION") || "top"
    property string pendingBarOrientation: barOrientation

    property string wallpaperDirectory: expandPath(Quickshell.env("WISP_WALLPAPER_DIR") || "~/Pictures/wallpapers")
    property string pendingWallpaperDirectory: wallpaperDirectory

    property string font: Quickshell.env("WISP_FONT") || "Noto Sans"
    property string pendingFont: font

    property bool packagesNotifyOnStartUp: envBool("WISP_PACKAGES_NOTIFY_ON_STARTUP", false)
    property bool pendingPackagesNotifyOnStartUp: packagesNotifyOnStartUp

    property bool packagesNotifyEveryDay: envBool("WISP_PACKAGES_NOTIFY_EVERY_DAY", false)
    property bool pendingPackagesNotifyEveryDay: packagesNotifyEveryDay

    property int batteryWarnPerc: parseInt(Quickshell.env("WISP_BATTERY_WARN_PERC")) || 30
    property int pendingBatteryWarnPerc: batteryWarnPerc

    property bool batteryAutoPowerSaver: envBool("WISP_BATTERY_AUTO_POWER_SAVER", false)
    property bool pendingBatteryAutoPowerSaver: batteryAutoPowerSaver

    property int notificationToastMs: parseInt(Quickshell.env("WISP_NOTIFICATION_TOAST_MS")) || 2000
    property int pendingNotificationToastMs: notificationToastMs

    property string jokesFilePath: expandPath(Quickshell.env("WISP_JOKES_FILE") || configDir + "/jokes.txt")
    property string pendingJokesFilePath: jokesFilePath

    property int osdDuration: parseInt(Quickshell.env("WISP_OSD_DURATION")) || 1000
    property int pendingOSDDuration: osdDuration

    property string osdOrientation: Quickshell.env("WISP_OSD_ORIENTATION") || "bottom"
    property string pendingOSDOrientation: osdOrientation

    // True whenever a staged setting differs from what's currently live.
    readonly property bool dirty: pendingTimeFormat !== timeFormat ||
                                  pendingBarOrientation !== barOrientation ||
                                  pendingWallpaperDirectory !== wallpaperDirectory ||
                                  pendingFont !== font ||
                                  pendingPackagesNotifyOnStartUp !== packagesNotifyOnStartUp ||
                                  pendingPackagesNotifyEveryDay !== packagesNotifyEveryDay ||
                                  pendingBatteryWarnPerc !== batteryWarnPerc ||
                                  pendingBatteryAutoPowerSaver !== batteryAutoPowerSaver ||
                                  pendingNotificationToastMs !== notificationToastMs ||
                                  pendingJokesFilePath !== jokesFilePath ||
                                  pendingOSDDuration !== osdDuration ||
                                  pendingOSDOrientation !== osdOrientation

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

    function stageBatteryWarnPerc(enabled) {
        pendingBatteryWarnPerc = enabled
    }

    function stageBatteryAutoPowerSaver(enabled) {
        pendingBatteryAutoPowerSaver = enabled
    }

    function stageNotificationToastMs(ms) {
        if (isNaN(ms)) return
        pendingNotificationToastMs = Math.max(500, Math.min(60000, ms))
    }

    function stageJokesFilePath(path) {
        pendingJokesFilePath = path
    }

    function stageOSDDuration(ms) {
        if (isNaN(ms)) return
        pendingOSDDuration = Math.max(0, Math.min(ms, Number.MAX_SAFE_INTEGER))
    }

    function stageOSDOrientation(orientation) {
        pendingOSDOrientation = orientation
    }

    function discardChanges() {
        pendingTimeFormat = timeFormat
        pendingBarOrientation = barOrientation
        pendingWallpaperDirectory = wallpaperDirectory
        pendingFont = font
        pendingPackagesNotifyOnStartUp = packagesNotifyOnStartUp
        pendingPackagesNotifyEveryDay = packagesNotifyEveryDay
        pendingBatteryWarnPerc = batteryWarnPerc
        pendingBatteryAutoPowerSaver = batteryAutoPowerSaver
        pendingNotificationToastMs = notificationToastMs
        pendingJokesFilePath = jokesFilePath
        pendingOSDDuration = osdDuration
        pendingOSDOrientation = osdOrientation
    }

    // Applies every pending setting to the live bar and rewrites
    // config.json, leaving unrelated keys (font, wallpaper, ...) as
    // they were.
    function save() {
        if (!dirty) return

        timeFormat = pendingTimeFormat
        Time.setFormatOverride(timeFormat)
        barOrientation = pendingBarOrientation
        wallpaperDirectory = expandPath(pendingWallpaperDirectory)
        pendingWallpaperDirectory = wallpaperDirectory
        font = pendingFont
        packagesNotifyOnStartUp = pendingPackagesNotifyOnStartUp
        packagesNotifyEveryDay = pendingPackagesNotifyEveryDay
        batteryWarnPerc = pendingBatteryWarnPerc
        Battery.warnPercent = batteryWarnPerc
        batteryAutoPowerSaver = pendingBatteryAutoPowerSaver
        Battery.autoPowerSaver = batteryAutoPowerSaver
        notificationToastMs = pendingNotificationToastMs
        jokesFilePath = expandPath(pendingJokesFilePath)
        pendingJokesFilePath = jokesFilePath
        osdDuration = pendingOSDDuration
        osdOrientation = pendingOSDOrientation

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

            if (!parsed.battery || typeof parsed.battery !== "object") parsed.battery = {}
            parsed.battery.warnPercentage = batteryWarnPerc
            parsed.battery.autoPowerSaver = batteryAutoPowerSaver

            if (!parsed.notifications || typeof parsed.notifications !== "object") parsed.notifications = {}
            parsed.notifications.toastDurationMs = notificationToastMs

            if (!parsed.welcome || typeof parsed.welcome !== "object") parsed.welcome = {}
            parsed.welcome.jokesFile = jokesFilePath

            if (!parsed.osd || typeof parsed.osd !== "object") parsed.osd = {}
            parsed.osd.duration = osdDuration
            parsed.osd.orientation = osdOrientation

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
