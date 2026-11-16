// qml/Bar/Clipboard/ClipboardSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Full `cliphist list` output, newest first.
    property var clipboardList: []
    property bool cliphistEnabled: true

    // Pins are keyed by preview text, NOT by cliphist id. cliphist dedups on
    // store, so re-copying a pinned entry gives it a new id. Keying by id
    // would silently unpin an item every time you use it.
    // Most recently pinned first. Persisted to ~/.config/wisp/clipboard-pins.json
    property var pinnedKeys: []

    // Max number of non-pinned entries shown in the history list.
    readonly property int historyLimit: 100

    // Pinned entries as current cliphist lines, in pin order.
    readonly property var pinnedList: {
        const byPreview = new Map()
        for (const line of root.clipboardList) {
            const key = root.previewOf(line)
            if (!byPreview.has(key))
                byPreview.set(key, line)
        }
        const out = []
        for (const key of root.pinnedKeys) {
            if (byPreview.has(key))
                out.push(byPreview.get(key))
        }
        return out
    }

    // Everything that is not pinned, so an entry never shows in both lists.
    readonly property var unpinnedList: {
        const pinned = new Set(root.pinnedKeys)
        return root.clipboardList
            .filter(line => !pinned.has(root.previewOf(line)))
            .slice(0, root.historyLimit)
    }

    // Maps a cliphist entry id -> decoded thumbnail file path on disk.
    // Populated lazily by decodeToFile() as image entries scroll into view.
    property var imageCache: ({})

    function previewOf(line) {
        return line.replace(/^\d+\t/, "")
    }

    function togglePin(line) {
        const key = root.previewOf(line)
        if (root.pinnedKeys.indexOf(key) === -1)
            root.pinnedKeys = [key].concat(root.pinnedKeys)
        else
            root.pinnedKeys = root.pinnedKeys.filter(k => k !== key)
        root.savePins()
    }

    function savePins() {
        pinsFile.setText(JSON.stringify(root.pinnedKeys))
    }

    // Drop pins whose entry no longer exists in cliphist. Skipped when the
    // list is empty so a failed `cliphist list` cannot wipe every pin.
    function prunePins(lines) {
        if (lines.length === 0)
            return
        const present = new Set(lines.map(l => root.previewOf(l)))
        const kept = root.pinnedKeys.filter(k => present.has(k))
        if (kept.length !== root.pinnedKeys.length) {
            root.pinnedKeys = kept
            root.savePins()
        }
    }

    function refreshClipboard() {
        getClipboard.running = true
    }

    function copyEntry(line) {
        copyProcess.entryLine = line
        copyProcess.running = true
    }

    function deleteEntry(line) {
        const idMatch = line.match(/^(\d+)/)
        if (idMatch && root.imageCache[idMatch[1]] !== undefined)
            delete root.imageCache[idMatch[1]]

        const key = root.previewOf(line)
        if (root.pinnedKeys.indexOf(key) !== -1) {
            root.pinnedKeys = root.pinnedKeys.filter(k => k !== key)
            root.savePins()
        }

        deleteProcess.entryLine = line
        deleteProcess.running = true
    }

    function clearAll() {
        root.imageCache = {}
        root.pinnedKeys = []
        root.savePins()
        clearProcess.running = true
    }

    // Decodes a cliphist "<id>\t[[ binary data ... ]]" line to an image file
    // on disk and hands the path to onDone(path); onDone("") on failure.
    function decodeToFile(line, onDone) {
        const idMatch = line.match(/^(\d+)/)
        const id = idMatch ? idMatch[1] : line

        if (root.imageCache[id]) {
            onDone(root.imageCache[id])
            return
        }

        const extMatch = line.match(/,\s*([a-zA-Z0-9]+)\s*\]\]\s*$/)
        const ext = extMatch ? extMatch[1].toLowerCase() : "png"
        const outPath = "/tmp/wisp-cliphist-thumb-" + id + "." + ext

        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { }',
            root,
            "clipboardDecodeProcess"
        )
        proc.command = ["bash", "-c", "cliphist decode <<< \"$0\" > \"$1\"", line, outPath]
        proc.exited.connect(function(exitCode) {
            if (exitCode === 0) {
                root.imageCache[id] = outPath
                onDone(outPath)
            } else {
                onDone("")
            }
            proc.destroy()
        })
        proc.running = true
    }

    // ----- Pin persistence -----

    FileView {
        id: pinsFile
        // path: Quickshell.env("HOME") + "/.config/wisp/clipboard-pins.json"
        path: {
            let clipDir = (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/wisp"
            return clipDir + "/clipboard-pins.json"
        }
        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                if (Array.isArray(parsed))
                    root.pinnedKeys = parsed.filter(k => typeof k === "string")
            } catch (e) {}
        }
    }

    // ----- Backing processes -----

    Process {
        id: getClipboard
        command: ["bash", "-c", "cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(line => line.length > 0)
                root.clipboardList = lines
                root.prunePins(lines)
            }
        }
    }

    // cliphist decode/delete both take the exact "<id>\t<preview>" line
    // from `cliphist list` on stdin, so we just forward modelData as-is.
    Process {
        id: copyProcess
        property string entryLine: ""
        command: ["bash", "-c", "cliphist decode <<< \"$0\" | wl-copy", entryLine]
    }

    Process {
        id: deleteProcess
        property string entryLine: ""
        command: ["bash", "-c", "cliphist delete <<< \"$0\"", entryLine]
        onExited: root.refreshClipboard()
    }

    Process {
        id: clearProcess
        command: ["cliphist", "wipe"]
        onExited: root.refreshClipboard()
    }

    Process {
        id: clipboardWatcher
        running: root.cliphistEnabled

        // wl-paste --watch fires its command once immediately for whatever is
        // *currently* on the clipboard, in addition to firing on future changes.
        // That means a plain "wl-paste --watch cliphist store" will re-store
        // the last thing added to the clipboard.
        command: [
            "bash", "-c",
            "touch /tmp/wisp-cliphist-skip; " +
            "exec wl-paste --watch bash -c '" +
            "if [ -e /tmp/wisp-cliphist-skip ]; then rm -f /tmp/wisp-cliphist-skip; else cliphist store; fi" +
            "'"
        ]

        onRunningChanged: {
            if (!running) {
                killWatcher.running = true
            }
        }
    }

    Process {
        id: killWatcher
        command: ["pkill", "-f", "wl-paste --watch"]
    }

    Component.onCompleted: refreshClipboard()
}
