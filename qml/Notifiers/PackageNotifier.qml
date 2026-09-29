// qml/Notifiers/PackageNotifier.qml

import QtQuick
import Quickshell
import Quickshell.Io
import "../Config"

// Headless service that sends a desktop notification when package updates are available.
Scope {
    id: root

    // Give the network / session a moment to settle after login before the
    // startup check (flatpak needs the network to see remote updates).
    readonly property int startupDelayMs: 30 * 1000
    readonly property real startupCooldownMs: 30 * 60 * 1000
    readonly property int pollIntervalMs: 15 * 60 * 1000
    readonly property real dailyIntervalMs: 24 * 60 * 60 * 1000

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/wisp"
    readonly property string statePath: stateDir + "/package-notifier-last-check"

    property bool checking: false
    property int pendingChecks: 0
    property int yayCount: 0
    property int flatpakCount: 0

    // Unix time in ms of the last check, 0 if there has never been one.
    property double lastCheckMs: 0

    function nonEmptyLines(text) {
        return text.split(/\r?\n/).filter(line => line.trim().length > 0)
    }

    function loadLastCheck() {
        try {
            const value = parseInt(stateFile.text().trim())
            // Ignore garbage and timestamps from the future (clock changes).
            if (isNaN(value) || value > Date.now()) return 0
            return value
        } catch (e) {
            // No state file yet, first run.
            return 0
        }
    }

    function saveLastCheck() {
        Quickshell.execDetached([
            "sh", "-c", 'mkdir -p "$1" && printf "%s" "$2" > "$3"',
            "sh", stateDir, String(lastCheckMs), statePath
        ])
    }

    function check(reason) {
        if (checking)
            return

        console.log("PackageNotifier: checking for updates (" + reason + ")")

        checking = true
        lastCheckMs = Date.now()
        saveLastCheck()
        yayCount = 0
        flatpakCount = 0
        pendingChecks = 2

        yayProc.running = true
        flatpakProc.running = true
    }

    function finishCheck() {
        pendingChecks = Math.max(0, pendingChecks - 1)
        if (pendingChecks > 0)
            return

        checking = false
        notifyIfNeeded()
    }

    function notifyIfNeeded() {
        const total = yayCount + flatpakCount
        if (total === 0)
            return

        const parts = []
        if (yayCount > 0) parts.push(yayCount + " Arch/AUR")
        if (flatpakCount > 0) parts.push(flatpakCount + " Flatpak")

        Quickshell.execDetached([
            "notify-send",
            "--app-name=Wisp",
            "--icon=system-software-update",
            total + (total === 1 ? " package update available" : " package updates available"),
            parts.join(", ")
        ])
    }

    FileView {
        id: stateFile
        path: root.statePath
        blockLoading: true
    }

    Process {
        id: yayProc
        command: ["yay", "-Qu"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.yayCount = root.nonEmptyLines(this.text).length
                root.finishCheck()
            }
        }
    }

    Process {
        id: flatpakProc
        command: ["flatpak", "remote-ls", "--updates", "--columns=application"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.flatpakCount = root.nonEmptyLines(this.text).length
                root.finishCheck()
            }
        }
    }

    // One-shot check shortly after startup. Started from onCompleted rather
    // than bound to the setting, so toggling it in the Settings UI later does
    // not trigger a surprise check.
    Timer {
        id: startupTimer
        interval: root.startupDelayMs
        repeat: false
        onTriggered: root.check("startup")
    }

    Component.onCompleted: {
        lastCheckMs = loadLastCheck()

        if (!Config.packagesNotifyOnStartUp)
            return

        if (Date.now() - lastCheckMs >= startupCooldownMs) {
            startupTimer.start()
        } else {
            console.log("PackageNotifier: skipping startup check, last check was recent")
        }
    }

    // Repeats the check once 24 hours have passed since the previous one.
    Timer {
        interval: root.pollIntervalMs
        running: Config.packagesNotifyEveryDay
        repeat: true
        onTriggered: {
            if (Date.now() - root.lastCheckMs >= root.dailyIntervalMs)
                root.check("daily")
        }
    }

    // Safety net: if a command never starts (yay or flatpak missing), don't
    // stay stuck in the "checking" state forever.
    Timer {
        interval: 2 * 60 * 1000
        running: root.checking
        repeat: false
        onTriggered: root.checking = false
    }
}
