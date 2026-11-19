// qml/Bar/Clipboard/ClipboardPopup.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import "../../Components"
import "../../Colors"
import "../../Config"
import "../../Icons"

BarPopup {
    id: clipboardPopup

    signal requestClose()

    property int currentIndex: 0
    property string searchText: ""

    // Shared clipboard state now lives in ClipboardSingleton so it stays in
    // sync across monitors instead of each popup keeping its own copy.
    readonly property var clipboardList: ClipboardSingleton.clipboardList
    readonly property bool cliphistEnabled: ClipboardSingleton.cliphistEnabled

    function applyFilter(list, searchText) {
        const needle = searchText.trim().toLowerCase()
        if (needle.length === 0)
            return list
        return list.filter(line => line.toLowerCase().indexOf(needle) !== -1)
    }

    // Pinned entries are shown first; an entry is never in both lists.
    readonly property var filteredPinned: applyFilter(ClipboardSingleton.pinnedList, clipboardPopup.searchText)
    readonly property var filteredHistory: applyFilter(ClipboardSingleton.unpinnedList, clipboardPopup.searchText)

    // Display order (pinned, then history).
    readonly property var filteredList: filteredPinned.concat(filteredHistory)

    function resetSelection() {
        clipboardPopup.currentIndex = 0
    }

    function closePopup() {
        clipboardPopup.requestClose()
    }

    function refreshClipboard() {
        ClipboardSingleton.refreshClipboard()
    }

    function copyEntry(line) {
        ClipboardSingleton.copyEntry(line)
    }

    function deleteEntry(line) {
        ClipboardSingleton.deleteEntry(line)
    }

    function clearAll() {
        ClipboardSingleton.clearAll()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ----- Search bar -----
        Rectangle {
            id: searchField
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: Colors.colors.surfaceAlt
            border.width: 1
            border.color: searchInput.activeFocus ? Colors.colors.accent : Colors.colors.borderSoft

            Behavior on border.color { ColorAnimation { duration: 120 } }

            HoverHandler {
                cursorShape: searchInput.activeFocus ? Qt.IBeamCursor : Qt.ArrowCursor
            }

            RowLayout {
                id: innerLayout
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6

                TintedIcon {
                    name: "ui/search"
                    tint: Colors.colors.foregroundMuted
                    Layout.preferredWidth: innerLayout.width * 0.075
                    Layout.preferredHeight: width
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        color: Colors.colors.foreground
                        font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter

                        onTextChanged: clipboardPopup.searchText = text
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search clipboard..."
                        color: Colors.colors.foregroundMuted
                        font.pixelSize: 13
                        font.family: Config.font
                        visible: searchInput.text.length === 0
                    }
                }

                Image {
                    source: Icons.getIcon("ui/close")
                    visible: searchInput.length > 0
                    fillMode: Image.PreserveAspectCrop

                    Layout.preferredWidth: innerLayout.width * 0.075
                    Layout.preferredHeight: width

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }

        // ----- Toggle + Clear row -----
        RowLayout {
            id: clearRow
            Layout.margins: 5
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 8

            ToggleButton {
                condition: clipboardPopup.cliphistEnabled
                label: "Save History?"
                onToggled: (newValue) => ClipboardSingleton.cliphistEnabled = newValue
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: clearButton
                implicitHeight: 22
                implicitWidth: clearRow.implicitWidth / 3
                radius: 6
                color: clearHover.hovered ? (confirmingClear ? Colors.colors.hover : Colors.colors.surfaceAlt) : "transparent"
                border.width: 1
                border.color: confirmingClear ? Colors.colors.error : Colors.colors.borderSoft

                property bool confirmingClear: false

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Timer {
                    id: confirmResetTimer
                    interval: 2500
                    onTriggered: clearButton.confirmingClear = false
                }

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: clearButton.confirmingClear ? "Confirm?" : "Clear all"
                    color: clearButton.confirmingClear ? Colors.colors.error : Colors.colors.foregroundMuted
                    font.pixelSize: 11
                    font.family: Config.font
                }

                HoverHandler { id: clearHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (clearButton.confirmingClear) {
                            confirmResetTimer.stop()
                            clearButton.confirmingClear = false
                            clipboardPopup.clearAll()
                        } else {
                            clearButton.confirmingClear = true
                            confirmResetTimer.restart()
                        }
                    }
                }
            }
        }

        // ----- List -----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true

                ListView {
                    id: listView
                    width: scrollView.width
                    model: clipboardPopup.filteredHistory
                    spacing: 4

                    // The Pinned section scrolls with the list as its header.
                    header: Column {
                        width: listView.width
                        spacing: 4
                        visible: pinnedRepeater.count > 0
                        height: visible ? implicitHeight : 0

                        Text {
                            text: "Pinned"
                            leftPadding: 4
                            color: Colors.colors.foregroundMuted
                            font.pixelSize: 11
                            font.family: Config.font
                        }

                        Repeater {
                            id: pinnedRepeater
                            model: clipboardPopup.filteredPinned

                            delegate: ClipboardEntry {
                                required property string modelData

                                width: listView.width
                                line: modelData
                                pinned: true

                                onActivated: {
                                    clipboardPopup.copyEntry(modelData)
                                    clipboardPopup.closePopup()
                                }
                            }
                        }

                        Text {
                            visible: clipboardPopup.filteredHistory.length > 0
                            topPadding: 6
                            leftPadding: 4
                            text: "History"
                            color: Colors.colors.foregroundMuted
                            font.pixelSize: 11
                            font.family: Config.font
                        }
                    }

                    delegate: ClipboardEntry {
                        required property string modelData

                        width: listView.width
                        line: modelData
                        pinned: false

                        onActivated: {
                            clipboardPopup.copyEntry(modelData)
                            clipboardPopup.closePopup()
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: clipboardPopup.filteredList.length === 0
                color: Colors.colors.foregroundMuted
                font.pixelSize: 12
                font.family: Config.font
                text: clipboardPopup.searchText.length > 0 ? "No matches" : "Clipboard history is empty"
            }
        }
    }
}
