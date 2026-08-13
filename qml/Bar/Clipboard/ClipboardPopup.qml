// qml/Bar/Clipboard/ClipboardPopup.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import "../../Components"
import "../../Colors"

BarPopup {
    id: clipboardPopup

    signal requestClose()

    property int currentIndex: 0
    property var clipboardList: []
    property string searchText: ""

    // Whether new copies get saved to cliphist.
    property bool cliphistEnabled: true

    readonly property var filteredList: {
        const list = clipboardPopup.clipboardList
        const needle = clipboardPopup.searchText.trim().toLowerCase()
        if (needle.length === 0)
            return list
        return list.filter(line => line.toLowerCase().indexOf(needle) !== -1)
    }

    function resetSelection() {
        clipboardPopup.currentIndex = 0
    }

    function closePopup() {
        clipboardPopup.requestClose()
    }

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

    // ----- Backing processes -----

    Process {
        id: getClipboard
        command: ["bash", "-c", "cliphist list | head -n 100"]
        stdout: StdioCollector {
            onStreamFinished: {
                clipboardPopup.clipboardList = this.text.split("\n").filter(line => line.length > 0)
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
        onExited: clipboardPopup.refreshClipboard()
    }

    Process {
        id: clearProcess
        command: ["cliphist", "wipe"]
        onExited: clipboardPopup.refreshClipboard()
    }

    Process {
        id: clipboardWatcher
        running: clipboardPopup.cliphistEnabled
        command: ["wl-paste", "--watch", "bash", "-c", "if [ \"$(cat /tmp/cliphist_saving_enabled 2>/dev/null)\" = \"true\" ]; then cliphist store; fi"]

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

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "⌕"
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 15
                    Layout.alignment: Qt.AlignVCenter
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
                        visible: searchInput.text.length === 0
                    }
                }

                Text {
                    text: "✕"
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 11
                    visible: searchInput.text.length > 0
                    Layout.alignment: Qt.AlignVCenter

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
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 8

            RowLayout {
                spacing: 6

                Rectangle {
                    id: toggleTrack
                    implicitWidth: 34
                    implicitHeight: 18
                    radius: height / 2
                    color: clipboardPopup.cliphistEnabled ? Colors.colors.accent : Colors.colors.surfaceAlt
                    border.width: 1
                    border.color: clipboardPopup.cliphistEnabled ? Colors.colors.accent : Colors.colors.borderSoft

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Colors.colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                        x: clipboardPopup.cliphistEnabled ? parent.width - width - 2 : 2

                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clipboardPopup.cliphistEnabled = !clipboardPopup.cliphistEnabled
                    }
                }

                Text {
                    text: "Save history"
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: clearButton
                implicitHeight: 22
                implicitWidth: clearLabel.implicitWidth + 16
                radius: 6
                color: clearHover.hovered ? (confirmingClear ? Colors.colors.error : Colors.colors.surfaceAlt) : "transparent"
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
                    text: clearButton.confirmingClear ? "Confirm clear?" : "Clear all"
                    color: clearButton.confirmingClear ? Colors.colors.error : Colors.colors.foregroundMuted
                    font.pixelSize: 11
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
                    model: clipboardPopup.filteredList
                    spacing: 4

                    delegate: Rectangle {
                        id: entryDelegate
                        required property string modelData
                        required property int index

                        width: listView.width
                        height: 35
                        radius: 6
                        color: itemHover.hovered ? Colors.colors.hover : Colors.colors.surface

                        Behavior on color { ColorAnimation { duration: 100 } }

                        HoverHandler { id: itemHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 4
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: entryDelegate.modelData.replace(/^\d+\t/, "")
                                color: Colors.colors.foreground
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                id: deleteButton
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: deleteHover.hovered ? Colors.colors.error : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 11
                                    color: deleteHover.hovered ? Colors.colors.background : Colors.colors.foregroundMuted
                                }

                                HoverHandler { id: deleteHover }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: clipboardPopup.deleteEntry(entryDelegate.modelData)
                                }
                            }
                        }

                        // Click anywhere except the delete button to copy + close.
                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 24
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                clipboardPopup.copyEntry(entryDelegate.modelData)
                                clipboardPopup.closePopup()
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: clipboardPopup.filteredList.length === 0
                color: Colors.colors.foregroundMuted
                font.pixelSize: 12
                text: clipboardPopup.searchText.length > 0 ? "No matches" : "Clipboard history is empty"
            }
        }
    }
}
