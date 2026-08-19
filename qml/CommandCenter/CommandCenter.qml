// qml/CommandCenter/CommandCenter.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../GlobalState"

PanelWindow {
    id: commandCenter

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: true

    // Starts closed by default, opens only when IPC command triggers it
    visible: GlobalState.commandCenter.isOpen

    property var sectionColumns: [
        {
            text: "Welcome"
        },
        {
            text: "Column 2"
        },
        {
            text: "Column 3"
        }        
    ]

    FocusScope {
        id: focusScope 
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: GlobalState.commandCenter.close()

        // Dim Screen behind
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Colors.colors.surfaceAlt.r, Colors.colors.surfaceAlt.g, Colors.colors.surfaceAlt.b, 0.2)

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalState.commandCenter.close()
            }    
        }

        Rectangle {
            id: winRect 
            anchors.centerIn: parent
            width: Math.min(800, parent.width - 80)
            height: Math.min(600, parent.height - 80)
            radius: 14
            color: Colors.colors.background
            border.color: Colors.colors.border
            border.width: 2

            // Swallow clicks so the dim screen's MouseArea doesn't see them
            MouseArea {
                anchors.fill: parent
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

                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignTop

                            color: Colors.colors.surfaceAlt
                            border.color: Colors.colors.border
                            border.width: 1
                            radius: 10

                            Text {
                                text: columnCard.modelData.text
                                font.family: "Iosevka Nerd Font Propo"
                                font.pixelSize: 12
                                color: Colors.colors.accentAlt
                                anchors.centerIn: parent
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
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

                    Rectangle {
                        id: welcomeBanner

                        Layout.fillWidth: true
                        Layout.maximumWidth: welcomeText.width + 25
                        Layout.preferredHeight: 45
                        Layout.alignment: Qt.AlignHCenter

                        color: Colors.colors.surfaceAlt
                        border.color: Colors.colors.border
                        border.width: 2
                        radius: welcomeBanner.width / 2

                        Text {
                            id: welcomeText
                            text: "Welcome to Wisp"
                            font.family: "Iosevka Nerd Font Propo"
                            font.pixelSize: 25
                            color: Colors.colors.accentAlt
                            anchors.centerIn: parent
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

            }
        }

    } // commandCenter
}
