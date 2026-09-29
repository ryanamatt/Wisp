// qml/Timer/Timer.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Colors"
import "../IpcState"
import "../Config"

FloatingWindow {
    id: timer

    title: "Wisp Timer"

    implicitWidth: 400
    implicitHeight: 250
    minimumSize: Qt.size(400, 250)

    color: "transparent"

    // Starts closed by default, opens only when IPC command triggers it
    visible: IpcState.timer.isOpen

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: IpcState.timer.close()

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
                onPressed: (mouse) => timer.startSystemMove()
                onClicked: (mouse) => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 2
                anchors.topMargin: 10

                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    Layout.leftMargin: 10 
                    Layout.rightMargin: 10
                    spacing: 2

                    TabButton { 
                        text: "Timer"
                        
                        contentItem: Text {
                            text: parent.text
                            color: parent.checked ? Colors.colors.background : Colors.colors.accentAlt
                            font.family: Config.font
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
                        text: "Stopwatch" 
                        
                        contentItem: Text {
                            text: parent.text
                            color: parent.checked ? Colors.colors.background : Colors.colors.accentAlt
                            font.family: Config.font
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

                    TimerTab {}
                    StopwatchTab {}
                }
            }

        }


    }

}
