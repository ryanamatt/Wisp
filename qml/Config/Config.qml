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

    property string barOrientation: Quickshell.env("WISP_BAR_ORIENTATION") || "top"

    property string font: Quickshell.env("WISP_FONT") || "Noto Sans"

    property string timeFormat: Quickshell.env("WISP_TIME_FORMAT") || "ddd MMM d hh:mm:ss AP"

    // Staged value edited by settings UI.
    property string pendingTimeFormat: timeFormat

    // True whenever a staged setting differs from what's currently live.
    readonly property bool dirty: pendingTimeFormat !== timeFormat

    // Called by settings UI as the user picks a new value.
    function stageTimeFormat(format) {
        pendingTimeFormat = format
    }

    function discardChanges() {
        pendingTimeFormat = timeFormat
    }

    // Applies every pending setting to the live bar and rewrites
    // config.json, leaving unrelated keys (font, wallpaper, apps...) as
    // they were.
    function save() {
        if (!dirty) return

        timeFormat = pendingTimeFormat
        Time.setFormatOverride(timeFormat)

        try {
            const raw = configFile.text()
            const parsed = raw.length > 0 ? JSON.parse(raw) : {}

            if (!parsed.bar || typeof parsed.bar !== "object") parsed.bar = {}
            parsed.bar.timeFormat = timeFormat

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
