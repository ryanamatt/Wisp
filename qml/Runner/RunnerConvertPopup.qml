// qml/Runner/RunnerConvertPopup.qml
//
// Shows the result of a "~" conversion. A single answer ("5 km mi") is drawn
// big, like the calculator. Several answers ("5 km", "#ff00ff", "0xff") are a
// list that the keyboard can walk through, and Enter copies the highlighted one.

import QtQuick
import QtQuick.Controls
import Quickshell
import "../Colors"
import "../Config"

RunnerBasePopup {
    id: root

    // ---- Inputs ----
    // `open` comes from the base. True while there is a valid conversion.
    // The map returned by Convert.convert():
    //   { ok, input, swatch, rows: [ { label, value, copy } ] }
    property var result: ({})

    // Emitted after a row was copied. Runner.qml closes itself on this.
    signal resultCopied(string text)

    // ---- Tweakables ----
    property int heroHeight: 80
    property int headerHeight: 30
    property int rowHeight: 36
    property int maxVisibleRows: 6
    readonly property color accentColor: Colors.colors.pink

    // ---- Internals ----
    // Last good result. Kept while closing, and while a half typed query is
    // invalid, so the card does not blank out or flicker.
    property string shownInput: ""
    property string shownSwatch: ""
    property var shownRows: []

    readonly property bool hero: shownRows.length === 1
    readonly property int visibleRows: Math.min(shownRows.length, maxVisibleRows)

    readonly property var current: {
        if (shownRows.length === 0) return null;
        if (hero) return shownRows[0];
        const i = list.currentIndex;
        return (i >= 0 && i < shownRows.length) ? shownRows[i] : null;
    }

    // ---- Base settings ----
    // Stops the popup from flickering while typing, e.g. "5 k" on the way to "5 km".
    closeDelay: 300
    openSlideDuration: 280
    closeSlideDuration: 180

    // The single answer is free-form content, the list gets normal padding.
    contentTopMargin: hero ? 0 : borderWidth * 2 + 6
    contentSideMargin: hero ? 0 : sidePadding + borderWidth
    popupHeight: hero
        ? heroHeight
        : contentTopMargin + headerHeight + visibleRows * rowHeight + footerHeight + borderWidth + 8

    showFooter: !hero && shownRows.length > 0
    footerText: current ? current.copy : ""
    footerHint: "\u21B5 copy"
    footerHintVisible: current !== null
    footerHintColor: accentColor

    function sync() {
        if (!open) return;
        if (!result || !result.ok) return;
        shownInput = result.input + " =";
        shownSwatch = result.swatch || "";
        shownRows = result.rows;
    }

    onOpenChanged: sync()
    onResultChanged: sync()

    // New rows, so start again from the first one.
    onShownRowsChanged: {
        list.currentIndex = shownRows.length > 1 ? 0 : -1;
        list.positionViewAtBeginning();
    }

    // ---- Actions (called from Runner.qml) ----
    function move(dy) {
        const n = shownRows.length;
        if (n < 2) return;

        const from = list.currentIndex < 0 ? 0 : list.currentIndex;
        const next = Math.max(0, Math.min(n - 1, from + dy));
        list.currentIndex = next;
        list.positionViewAtIndex(next, ListView.Contain);
    }

    function activate() {
        if (current) copyRow(current);
    }

    function copyRow(row) {
        // Detached so the clipboard owner outlives the Runner closing.
        Quickshell.execDetached(["wl-copy", "--", row.copy]);
        resultCopied(row.copy);
    }

    // ---- Single answer ----
    Column {
        id: heroColumn
        visible: root.hero
        anchors.centerIn: parent
        width: parent.width - 48
        spacing: 2

        // The input, repeated back
        Text {
            width: parent.width
            text: root.shownInput
            color: Colors.colors.foregroundSubtle
            font.pixelSize: 20
            font.family: Config.font
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Row {
            id: heroRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Rectangle {
                id: heroSwatch
                anchors.verticalCenter: parent.verticalCenter
                visible: root.shownSwatch !== ""
                width: 22
                height: 22
                radius: 11
                color: root.shownSwatch === "" ? "transparent" : root.shownSwatch
                border.width: 1
                border.color: Colors.colors.border
            }

            Text {
                id: heroValue
                anchors.verticalCenter: parent.verticalCenter
                text: root.hero ? root.shownRows[0].value : ""
                color: root.accentColor
                font.pixelSize: 26
                font.bold: true
                font.family: Config.font
                elide: Text.ElideRight
                transformOrigin: Item.Center

                // Never wider than the card, long binary strings get cut.
                width: Math.min(implicitWidth, heroColumn.width
                    - (heroSwatch.visible ? heroSwatch.width + heroRow.spacing : 0)
                    - (heroLabel.visible ? heroLabel.width + heroRow.spacing : 0))

                // Small pop whenever the answer changes while visible.
                onTextChanged: if (root.slideProgress > 0.99) bump.restart()

                SequentialAnimation {
                    id: bump
                    NumberAnimation {
                        target: heroValue; property: "scale"
                        to: 1.08; duration: 70; easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: heroValue; property: "scale"
                        to: 1.0; duration: 160; easing.type: Easing.OutBack
                    }
                }
            }

            Text {
                id: heroLabel
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 2
                text: root.hero ? root.shownRows[0].label : ""
                visible: text !== ""
                color: Colors.colors.foregroundSubtle
                font.pixelSize: 18
                font.family: Config.font
            }
        }
    }

    // ---- List of answers ----
    Item {
        id: listArea
        visible: !root.hero
        anchors.fill: parent

        // The input, repeated back, with a colour swatch when there is one.
        Item {
            id: header
            width: parent.width
            height: root.headerHeight

            Rectangle {
                id: headSwatch
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                visible: root.shownSwatch !== ""
                width: 18
                height: 18
                radius: 9
                color: root.shownSwatch === "" ? "transparent" : root.shownSwatch
                border.width: 1
                border.color: Colors.colors.border
            }

            Text {
                anchors.left: headSwatch.visible ? headSwatch.right : parent.left
                anchors.leftMargin: headSwatch.visible ? 8 : 6
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.shownInput
                color: Colors.colors.foregroundSubtle
                font.pixelSize: 16
                font.family: Config.font
                elide: Text.ElideRight
            }
        }

        ListView {
            id: list

            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            model: root.shownRows
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
                    radius: 10
                    color: row.isCurrent ? Colors.colors.selected : "transparent"
                    border.width: row.isCurrent ? 1 : 0
                    border.color: Colors.colors.borderActive

                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: rowLabel.visible ? rowLabel.left : parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.value
                    color: Colors.colors.foreground
                    font.pixelSize: 17
                    font.family: Config.font
                    elide: Text.ElideRight
                }

                Text {
                    id: rowLabel
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    visible: text !== ""
                    color: root.accentColor
                    font.pixelSize: 14
                    font.family: Config.font
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    // Only real mouse movement moves the selection, so a view
                    // scrolling under a still cursor does not steal it.
                    onPositionChanged: list.currentIndex = row.index
                    onClicked: root.copyRow(row.modelData)
                }
            }
        }
    }
}
