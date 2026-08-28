// qml/Screenshot/Screenshot.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../GlobalState"

FloatingWindow {
    id: screenshot

    title: "Wisp Screenshot"

    implicitWidth: 300
    implicitHeight: 100
    minimumSize: Qt.size(400, 200)

    color: "transparent"

    // Starts closed by default, opens only when IPC command triggers it
    visible: GlobalState.screenshot.isOpen

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: GlobalState.screenshot.close()

        Rectangle {
            id: winRect

            anchors.fill: parent
            radius: 14
            color: Colors.colors.background
            border.color: Colors.colors.border
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: screenshot.implicitHeight / 5
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    color: Colors.colors.accent
                    text: "Wisp Screenshot"
                    font.bold: true
                    font.pixelSize: Layout.preferredHeight * 0.75
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    Layout.leftMargin: 10 
                    Layout.rightMargin: 10
                    spacing: 2

                    TabButton { 
                        text: "Screenshot"
                        
                        contentItem: Text {
                            text: parent.text
                            color: parent.checked ? Colors.colors.background : Colors.colors.accentAlt
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        
                        background: Rectangle {
                            color: parent.checked ? Colors.colors.accent : Colors.colors.surfaceAlt
                            topLeftRadius: 25
                        }
                    }

                    TabButton { 
                        text: "Video" 
                        
                        contentItem: Text {
                            text: parent.text
                            color: parent.checked ? Colors.colors.background : Colors.colors.accentAlt
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        
                        background: Rectangle {
                            color: parent.checked ? Colors.colors.accent : Colors.colors.surfaceAlt
                            topRightRadius: 25
                        }    
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabBar.currentIndex

                    ScreenshotTab {}
                    VideoTab {}
                }
            }

        }

    }

}