//qml/CommandCenter/CommandCenter.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../GlobalState"
import "SystemSection"
import "WelcomeSection"
import Wisp.Version

FloatingWindow {
    id: commandCenter

    title: "Command Center"

    implicitWidth: 800
    implicitHeight: 600
    minimumSize: Qt.size(800, 600)

    color: "transparent"

    // Starts closed by default, opens only when IPC command triggers it
    visible: GlobalState.commandCenter.isOpen

    property var sectionColumns: [
        {
            id: "welcome",
            text: "Welcome"
        },
        {
            id: "system",
            text: "System"
        },     
    ]

    // Which section card is currently selected
    property int currentIndex: 0
    readonly property var currentSection: sectionColumns[currentIndex]

    function sectionFile(id) {
        return id.charAt(0).toUpperCase() + id.slice(1) + "Section/" + id.charAt(0).toUpperCase() + id.slice(1) + "Section.qml"
    }

    FocusScope {
        id: focusScope 
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: GlobalState.commandCenter.close()

        Rectangle {
            id: winRect

            anchors.fill: parent
            radius: 14
            color: Colors.colors.background
            border.color: Colors.colors.border
            border.width: 2

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: (mouse) => commandCenter.startSystemMove()
                onClicked: (mouse) => mouse.accepted = true
            }

            RowLayout {
                id: mainRow
                anchors.fill: parent
                anchors.margins: 8
                spacing: 0

                ColumnLayout {
                    id: sectionsLayout

                    Layout.preferredWidth: mainRow.width * 0.2
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.fillWidth: false
                    Layout.fillHeight: true

                    clip: true

                    spacing: 10

                    Text {
                        text: "Command Center"
                        font.family: "Iosevka Nerd Font Propo"
                        font.pixelSize: 16
                        font.bold: true
                        color: Colors.colors.accent
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Repeater {
                        model: commandCenter.sectionColumns

                        delegate : Rectangle {
                            id: columnCard

                            required property var modelData
                            required property int index

                            readonly property bool isActive: commandCenter.currentIndex === index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignTop

                            color: columnCard.isActive ? Colors.colors.accent : Colors.colors.surfaceAlt
                            border.color: Colors.colors.border
                            border.width: 1
                            radius: 10

                            Text {
                                text: columnCard.modelData.text
                                font.family: "Iosevka Nerd Font Propo"
                                font.pixelSize: 12
                                color: columnCard.isActive ? Colors.colors.background : Colors.colors.accentAlt
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: commandCenter.currentIndex = columnCard.index
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Text {
                        id: versionText
                        Layout.alignment: Qt.AlignHCenter
                        Layout.rightMargin: 6
                        Layout.bottomMargin: 4

                        text: WispVersion.version
                        font.family: "Iosevka Nerd Font Propo"
                        font.pixelSize: 10
                        color: Colors.colors.foregroundMuted
                        opacity: 0.7
                    }
                }

                Item {
                    Layout.preferredWidth: 8
                    Layout.fillHeight: true
                    clip: true
                }

                Rectangle {
                    id: splitter
                    clip: true

                    Layout.fillHeight: true
                    implicitWidth: 5

                    radius: 10

                    color: Colors.colors.borderSoft
                }

                Item {
                    Layout.preferredWidth: 8
                    Layout.fillHeight: true
                    clip: true
                }

                ColumnLayout {
                    id: informationLayout

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.maximumWidth: Infinity

                    clip: true
                    spacing: 20

                    Loader {
                        id: sectionLoader

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        source: commandCenter.sectionFile(commandCenter.currentSection.id)
                    }
                }

            }
        }

    } 
}
