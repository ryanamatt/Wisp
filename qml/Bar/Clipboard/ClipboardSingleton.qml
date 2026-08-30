// qml/Bar/Clipboard/ClipboardSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ----- Shared state (was previously duplicated per-monitor in ClipboardPopup) -----

    property var clipboardList: []
    property bool cliphistEnabled: true

    // Maps a cliphist entry id -> decoded thumbnail file path on disk.
    // Populated lazily by decodeToFile() as image entries scroll into view.
    property var imageCache: ({})

    // ----- Public API -----

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

        deleteProcess.entryLine = line
        deleteProcess.running = true
    }

    function clearAll() {
        root.imageCache = {}
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

    // ----- Backing processes (single instance, shared across all screens) -----

    Process {
        id: getClipboard
        command: ["bash", "-c", "cliphist list | head -n 100"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.clipboardList = this.text.split("\n").filter(line => line.length > 0)
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
