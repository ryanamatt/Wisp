// qml/Runner/RunnerSymbolPopup.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../Colors"
import "../Config"
import "SymbolIndex.js" as SymbolIndex

PanelWindow {
    id: root

    // ---- Inputs ----
    // True while the Runner is in symbol mode.
    property bool open: false
    // Text typed after the leading ":".
    property string query: ""

    // Geometry of the Runner this popup hangs from.
    property int runnerWidth: 400
    property int runnerHeight: 100
    property int runnerTopMargin: 0

    // ---- Data sources ----
    // Emoji and common symbols, with names and keywords.
    // Arch: unicode-cldr-annotations   Debian/Ubuntu: unicode-cldr-core
    property string annotationsPath: "/usr/share/unicode/cldr/common/annotations/en.xml"
    // Extra blocks (Greek, box drawing, fractions, ...). Optional.
    // Arch: unicode-character-database   Debian/Ubuntu: unicode-data
    property string unicodeDataPath: "/usr/share/unicode/UnicodeData.txt"

    // ---- Tweakables ----
    property int popupWidth: runnerWidth
    property int popupHeight: 340
    property int bottomRadius: 30
    property int columns: 8
    property int glyphSize: 24
    property int footerHeight: 44
    property int sidePadding: 14

    readonly property int borderWidth: 2

    // Emitted after a symbol was copied. Runner.qml closes itself on this.
    signal symbolCopied(string symbol)

    // ---- Animation state ----
    property real cornerProgress: 0
    property real slideProgress: 0

    // ---- Internals ----
    property bool expanded: false

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

    // ---- Open / close animation (same scheme as RunnerCalcPopup) ----
    function setExpanded(value) {
        if (value === expanded) return;
        expanded = value;

        openAnim.stop();
        closeAnim.stop();

        // Scale durations by the distance left so interrupting is seamless.
        if (value) {
            openCorners.duration = Math.round(90 * (1 - cornerProgress));
            openSlide.duration = Math.round(320 * (1 - slideProgress));
            openAnim.start();
        } else {
            closeSlide.duration = Math.round(200 * slideProgress);
            closeCorners.duration = Math.round(90 * cornerProgress);
            closeAnim.start();
        }
    }

    // Jump straight to closed with no animation (used when the Runner hides).
    function snapClosed() {
        openAnim.stop();
        closeAnim.stop();
        expanded = false;
        cornerProgress = 0;
        slideProgress = 0;
    }

    onOpenChanged: {
        if (open && !loadRequested) {
            cldrState = "loading";
            ucdState = "loading";
            loadRequested = true;
        }
        setExpanded(open);
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation {
            id: openCorners
            target: root; property: "cornerProgress"
            to: 1; duration: 90; easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            id: openSlide
            target: root; property: "slideProgress"
            to: 1; duration: 320; easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            id: closeSlide
            target: root; property: "slideProgress"
            to: 0; duration: 200; easing.type: Easing.InCubic
        }
        NumberAnimation {
            id: closeCorners
            target: root; property: "cornerProgress"
            to: 0; duration: 90; easing.type: Easing.InOutQuad
        }
    }

    // ---- Window ----
    visible: expanded || cornerProgress > 0 || slideProgress > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true }
    // Overlap the Runner by one border width so the two borders merge.
    margins.top: runnerTopMargin + runnerHeight - borderWidth

    implicitWidth: popupWidth
    implicitHeight: popupHeight

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: card
            visible: root.slideProgress > 0

            width: parent.width
            // Extra border width on top, pushed above the clip edge, so only
            // the side and bottom borders are visible.
            height: root.popupHeight + root.borderWidth
            y: -root.borderWidth - (1 - root.slideProgress) * root.popupHeight

            color: Colors.colors.backgroundAlt
            border.color: Colors.colors.background
            border.width: root.borderWidth

            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: root.bottomRadius
            bottomRightRadius: root.bottomRadius

            // ---- Symbol grid ----
            Item {
                id: gridArea
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: footer.top
                    topMargin: root.borderWidth * 2 + 6
                    leftMargin: root.sidePadding + root.borderWidth
                    rightMargin: root.sidePadding + root.borderWidth
                }

                GridView {
                    id: grid

                    // Fit whole cells and centre the leftover pixels.
                    readonly property int cell: Math.floor(gridArea.width / root.columns)

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

                // Shown instead of the grid when there is nothing to list.
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    visible: root.results.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: Colors.colors.foregroundSubtle
                    font.pixelSize: 14
                    font.family: Config.font
                    text: {
                        if (root.loading)
                            return "Loading symbols...";
                        if (root.noData)
                            return "No symbol data found.\nCould not read " + root.annotationsPath;
                        return "No symbols match '" + root.query.trim() + "'";
                    }
                }
            }

            // ---- Footer: name of the highlighted symbol ----
            Item {
                id: footer
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: root.borderWidth
                }
                height: root.footerHeight

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.bottomRadius
                    anchors.rightMargin: root.bottomRadius
                    height: 1
                    color: Colors.colors.border
                    opacity: 0.6
                }

                Text {
                    id: hintText
                    anchors.right: parent.right
                    anchors.rightMargin: root.bottomRadius
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 1
                    visible: root.current !== null
                    text: "\u21B5 copy"
                    color: Colors.colors.purple
                    font.pixelSize: 12
                    font.family: Config.font
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.bottomRadius
                    anchors.right: hintText.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 1
                    text: root.current ? root.current.c + "   " + root.current.n : ""
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 14
                    font.family: Config.font
                    elide: Text.ElideRight
                }
            }
        }
    }
}
