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

    // ----- Public API -----

    function refreshClipboard() {
        getClipboard.running = true
    }

    function copyEntry(line) {
        copyProcess.entryLine = line
        copyProcess.running = true
    }

    function deleteEntry(line) {
        deleteProcess.entryLine = line
        deleteProcess.running = true
    }

    function clearAll() {
        clearProcess.running = true
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
