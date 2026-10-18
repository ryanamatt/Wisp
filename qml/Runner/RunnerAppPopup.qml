// qml/Runner/RunnerAppPopup.qml
//
// Application launcher list. Apps come from Quickshell's DesktopEntries, which
// scans the XDG .desktop directories and keeps itself up to date.

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../Colors"
import "../Config"
import "AppIndex.js" as AppIndex

PanelWindow {
    id: root

    // ---- Inputs ----
    // True while the Runner is in app mode (or idle, when showing recents).
    property bool open: false
    // Text typed into the Runner.
    property string query: ""

    // Geometry of the Runner this popup hangs from.
    property int runnerWidth: 400
    property int runnerHeight: 100
    property int runnerTopMargin: 0

    // ---- Tweakables ----
    property int popupWidth: runnerWidth
    property int popupHeight: 344
    property int bottomRadius: 30
    property int rowHeight: 48
    property int iconSize: 32
    property int footerHeight: 44
    property int sidePadding: 14

    // Used for .desktop files with Terminal=true. $TERMINAL is only set if the
    // shell inherited it, so xdg-terminal-exec is the fallback.
    property string terminal: Quickshell.env("TERMINAL") || "xdg-terminal-exec"

    readonly property int borderWidth: 2

    // Emitted after an app was launched. Runner.qml closes itself on this.
    signal appLaunched(string id)

    // ---- Animation state ----
    property real cornerProgress: 0
    property real slideProgress: 0

    // ---- Internals ----
    property bool expanded: false

    // Rebuilt automatically when apps are installed or removed.
    readonly property var entries: AppIndex.build(DesktopEntries.applications.values)

    // { desktopId: { c: launches, t: lastLaunchMs } }
    property var usage: ({})

    readonly property var results: AppIndex.search(entries, query, usage, Date.now())
    readonly property var current: (list.currentIndex >= 0 && list.currentIndex < results.length)
        ? results[list.currentIndex]
        : null

    readonly property int pageSize: Math.max(1, Math.floor(list.height / rowHeight) - 1)

    // New results, so start again from the first row.
    onResultsChanged: {
        const targetIndex = results.length > 0 ? 0 : -1;
        if (list.currentIndex !== targetIndex) list.currentIndex = targetIndex;
        list.positionViewAtBeginning();
    }

    // ---- Launch history ----
    readonly property string historyDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/wisp"
    readonly property string historyPath: historyDir + "/app-history.json"

    // FileView will not create parent directories.
    Process {
        command: ["mkdir", "-p", root.historyDir]
        running: true
    }

    FileView {
        id: historyFile
        path: root.historyPath
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object") root.usage = parsed;
            } catch (e) {}
        }
    }

    function recordLaunch(id) {
        const next = Object.assign({}, usage);
        const prev = next[id] || { c: 0, t: 0 };
        next[id] = { c: prev.c + 1, t: Date.now() };
        usage = next;
        historyFile.setText(JSON.stringify(next));
    }

    // ---- Actions (called from Runner.qml) ----
    function move(delta) {
        const n = results.length;
        if (n === 0) return;

        const from = list.currentIndex < 0 ? 0 : list.currentIndex;
        const next = Math.max(0, Math.min(n - 1, from + delta));
        list.currentIndex = next;
        list.positionViewAtIndex(next, ListView.Contain);
    }

    function activate() {
        if (current) launch(current);
    }

    function terminalCommand(cmd) {
        const base = root.terminal.split("/").pop();
        const prefix = base === "xdg-terminal-exec" ? [root.terminal] : [root.terminal, "-e"];
        return prefix.concat(cmd);
    }

    function launch(item) {
        const e = item.entry;
        recordLaunch(item.id);

        if (e.runInTerminal) {
            const ctx = { command: terminalCommand(e.command) };
            if (e.workingDirectory) ctx.workingDirectory = e.workingDirectory;
            // Detached so the app outlives the Runner closing.
            Quickshell.execDetached(ctx);
        } else {
            e.execute();
        }
        appLaunched(item.id);
    }

    // Returns "" when the icon is not in the theme. The letter tile in the
    // delegate covers that case, and no image request means no warning.
    function iconSource(name) {
        if (!name) return "";
        if (name.charAt(0) === "/") return "file://" + name;
        return Quickshell.iconPath(name, true);
    }

    // ---- Open / close animation (same scheme as RunnerSymbolPopup) ----
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

    onOpenChanged: setExpanded(open)

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

            // ---- App list ----
            Item {
                id: listArea
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: footer.top
                    topMargin: root.borderWidth * 2 + 6
                    leftMargin: root.sidePadding + root.borderWidth
                    rightMargin: root.sidePadding + root.borderWidth
                }

                ListView {
                    id: list
                    anchors.fill: parent

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
                        id: row

                        required property int index
                        required property var modelData

                        readonly property bool isCurrent: ListView.isCurrentItem

                        width: list.width
                        height: root.rowHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 12
                            color: row.isCurrent ? Colors.colors.selected : "transparent"
                            border.width: row.isCurrent ? 1 : 0
                            border.color: Colors.colors.borderActive

                            Behavior on color { ColorAnimation { duration: 90 } }
                        }

                        // The app's own icon, installed by the app itself.
                        Item {
                            id: iconBox
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.iconSize
                            height: root.iconSize

                            // Letter tile, only visible when the icon is missing.
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                visible: appIcon.status !== Image.Ready
                                color: Colors.colors.surfaceElevated

                                Text {
                                    anchors.centerIn: parent
                                    text: row.modelData.name.charAt(0).toUpperCase()
                                    color: Colors.colors.accent
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: Config.font
                                }
                            }

                            IconImage {
                                id: appIcon
                                anchors.fill: parent
                                implicitSize: root.iconSize
                                asynchronous: true
                                source: root.iconSource(row.modelData.icon)
                            }
                        }

                        Column {
                            anchors.left: iconBox.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: row.modelData.name
                                color: Colors.colors.foreground
                                font.pixelSize: 15
                                font.family: Config.font
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                visible: row.modelData.detail !== ""
                                text: row.modelData.detail
                                color: Colors.colors.foregroundSubtle
                                font.pixelSize: 11
                                font.family: Config.font
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            // Only real mouse movement moves the selection, so
                            // a list scrolling under a still cursor (keyboard
                            // navigation) does not steal it.
                            onPositionChanged: list.currentIndex = row.index
                            onClicked: root.launch(row.modelData)
                        }
                    }
                }

                // Shown instead of the list when there is nothing to list.
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    visible: root.results.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: Colors.colors.foregroundSubtle
                    font.pixelSize: 14
                    font.family: Config.font
                    text: root.entries.length === 0
                        ? "No applications found."
                        : "No apps match '" + root.query.trim() + "'\n> command   = calculate   : symbols"
                }
            }

            // ---- Footer: details of the highlighted app ----
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
                    text: "\u21B5 launch"
                    color: Colors.colors.accent
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
                    text: root.current ? root.current.name : ""
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 14
                    font.family: Config.font
                    elide: Text.ElideRight
                }
            }
        }
    }
}
