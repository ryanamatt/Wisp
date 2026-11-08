// qml/Runner/RunnerSymbolPopup.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../Colors"
import "../Config"
import "SymbolIndex.js" as SymbolIndex

RunnerBasePopup {
    id: root

    // ---- Inputs ----
    // `open` comes from the base. True while the Runner is in symbol mode.
    // Text typed after the leading ":".
    property string query: ""

    // ---- Data sources ----
    // Emoji and common symbols, with names and keywords.
    // Arch: unicode-cldr-annotations   Debian/Ubuntu: unicode-cldr-core
    property string annotationsPath: "/usr/share/unicode/cldr/common/annotations/en.xml"
    // Extra blocks (Greek, box drawing, fractions, ...). Optional.
    // Arch: unicode-character-database
    property string unicodeDataPath: "/usr/share/unicode/UnicodeData.txt"

    // ---- Tweakables ----
    property int columns: 8
    property int glyphSize: 24

    // Emitted after a symbol was copied. Runner.qml closes itself on this.
    signal symbolCopied(string symbol)

    // ---- Base settings ----
    popupHeight: 340
    showFooter: true
    footerText: current ? current.c + "   " + current.n : ""
    footerHint: "\u21B5 copy"
    footerHintVisible: current !== null
    footerHintColor: Colors.colors.purple
    emptyVisible: results.length === 0
    emptyText: {
        if (loading)
            return "Loading symbols...";
        if (noData)
            return "No symbol data found.\nCould not read " + annotationsPath;
        return "No symbols match '" + query.trim() + "'";
    }

    // ---- Internals ----
    // Files are only read once the popup has been opened for the first time.
    property bool loadRequested: false
    // "idle" | "loading" | "ok" | "missing" for each source.
    property string cldrState: "idle"
    property string ucdState: "idle"
    property string cldrText: ""
    property string ucdText: ""

    property var entries: []

    readonly property bool loading: loadRequested && (cldrState === "loading" || ucdState === "loading")
    readonly property bool noData: loadRequested && !loading && entries.length === 0

    readonly property var results: SymbolIndex.search(entries, query)
    readonly property var current: (grid.currentIndex >= 0 && grid.currentIndex < results.length)
        ? results[grid.currentIndex]
        : null

    // Build the index once every source has either loaded or failed.
    function maybeBuild() {
        if (cldrState === "loading" || ucdState === "loading") return;
        entries = SymbolIndex.build(cldrText, ucdText);
        cldrText = "";
        ucdText = "";
    }

    // New search results, so start again from the first cell.
    onResultsChanged: {
        const targetIndex = results.length > 0 ? 0 : -1;
        if (grid.currentIndex !== targetIndex) {
            grid.currentIndex = targetIndex;
        }
        grid.positionViewAtBeginning();
    }

    // Kick off the file loads the first time the popup opens.
    onOpenChanged: {
        if (open && !loadRequested) {
            cldrState = "loading";
            ucdState = "loading";
            loadRequested = true;
        }
    }

    FileView {
        id: cldrFile
        path: root.loadRequested ? root.annotationsPath : ""
        onLoaded: {
            root.cldrText = text();
            root.cldrState = "ok";
            root.maybeBuild();
        }
        onLoadFailed: {
            root.cldrState = "missing";
            root.maybeBuild();
        }
    }

    FileView {
        id: ucdFile
        path: root.loadRequested ? root.unicodeDataPath : ""
        onLoaded: {
            root.ucdText = text();
            root.ucdState = "ok";
            root.maybeBuild();
        }
        onLoadFailed: {
            root.ucdState = "missing";
            root.maybeBuild();
        }
    }

    // ---- Actions (called from Runner.qml) ----
    function move(dx, dy) {
        const n = results.length;
        if (n === 0) return;

        const from = grid.currentIndex < 0 ? 0 : grid.currentIndex;
        const next = Math.max(0, Math.min(n - 1, from + dx + dy * columns));
        grid.currentIndex = next;
        grid.positionViewAtIndex(next, GridView.Contain);
    }

    function activate() {
        if (current) copySymbol(current.c);
    }

    function copySymbol(glyph) {
        // Detached so the clipboard owner outlives the Runner closing.
        Quickshell.execDetached(["wl-copy", "--", glyph]);
        symbolCopied(glyph);
    }

    // ---- Symbol grid ----
    GridView {
        id: grid

        // Fit whole cells and centre the leftover pixels. The parent is the
        // base's content area.
        readonly property int cell: Math.floor(parent.width / root.columns)

        anchors.horizontalCenter: parent.horizontalCenter
        width: cell * root.columns
        height: parent.height

        cellWidth: cell
        cellHeight: cell

        model: root.results
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // The text field owns the keyboard, Runner.qml calls move().
        keyNavigationEnabled: false
        interactive: true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Colors.colors.foregroundDisabled
                opacity: parent.active ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        delegate: Item {
            id: cell

            required property int index
            required property var modelData

            readonly property bool isCurrent: GridView.isCurrentItem

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 10
                color: cell.isCurrent ? Colors.colors.selected : "transparent"
                border.width: cell.isCurrent ? 1 : 0
                border.color: Colors.colors.borderActive

                Behavior on color { ColorAnimation { duration: 90 } }
            }

            Text {
                anchors.centerIn: parent
                text: cell.modelData.c
                color: Colors.colors.foreground
                font.pixelSize: root.glyphSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                // Only real mouse movement moves the selection, so
                // a view scrolling under a still cursor (keyboard
                // navigation) does not steal it.
                onPositionChanged: grid.currentIndex = cell.index
                onClicked: root.copySymbol(cell.modelData.c)
            }
        }
    }
}
