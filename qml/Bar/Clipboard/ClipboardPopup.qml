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
    property string searchText: ""

    // Shared clipboard state now lives in ClipboardSingleton so it stays in
    // sync across monitors instead of each popup keeping its own copy.
    readonly property var clipboardList: ClipboardSingleton.clipboardList
    readonly property bool cliphistEnabled: ClipboardSingleton.cliphistEnabled

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
                        onClicked: ClipboardSingleton.cliphistEnabled = !ClipboardSingleton.cliphistEnabled
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

                        readonly property string previewText: entryDelegate.modelData.replace(/^\d+\t/, "")
                        readonly property bool isImage: /^\[\[\s*binary data/i.test(entryDelegate.previewText)
                        property string imagePath: ""

                        // Friendly label for image entries, e.g. "1.2 MiB · 1920x1080 · png"
                        readonly property string imageLabel: {
                            const m = entryDelegate.previewText.match(/binary data\s*([^,\]]+)(?:,\s*(\d+x\d+))?(?:,\s*([a-zA-Z0-9]+))?/i)
                            if (!m)
                                return entryDelegate.previewText
                            return [m[1] ? m[1].trim() : "", m[2], m[3]].filter(Boolean).join(" · ")
                        }

                        width: listView.width
                        height: entryDelegate.isImage ? 52 : 35
                        radius: 6
                        color: itemHover.hovered ? Colors.colors.hover : Colors.colors.surface

                        Behavior on color { ColorAnimation { duration: 100 } }

                        HoverHandler { id: itemHover }

                        Component.onCompleted: {
                            if (entryDelegate.isImage) {
                                ClipboardSingleton.decodeToFile(entryDelegate.modelData, function(path) {
                                    entryDelegate.imagePath = path
                                })
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 4
                            spacing: 8

                            Rectangle {
                                visible: entryDelegate.isImage
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignVCenter
                                radius: 4
                                color: Colors.colors.surfaceAlt
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    visible: entryDelegate.imagePath.length > 0
                                    source: entryDelegate.imagePath.length > 0 ? ("file://" + entryDelegate.imagePath) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    smooth: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: entryDelegate.isImage ? entryDelegate.imageLabel : entryDelegate.previewText
                                color: Colors.colors.foreground
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                id: deleteButton
                                implicitWidth: 20
                                implicitHeight: 20
                                Layout.alignment: Qt.AlignVCenter
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
