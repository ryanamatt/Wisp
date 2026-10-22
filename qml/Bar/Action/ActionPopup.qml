// qml/bar/Action/ActionPopup.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"
import "../../Components"
import "../../Icons"
import "../../WispState"

BarPopup {
    id: root

    property bool tempCondition: false

    signal requestClose()
    property int currentIndex: 0

    function resetSelection() {
        root.currentIndex = 0
    }

    ColumnLayout {
        id: rootLayout

        anchors.centerIn: parent

        RowLayout {
            id: gameModeLayout
            Layout.fillWidth: true

            Image {
                id: gameModeImage

                source: tempCondition ? Icons.getIcon("gameModeOn") :
                    Icons.getIcon("gameModeOff")
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio

                Layout.preferredWidth: rootLayout.width * 0.25
                Layout.preferredHeight: width
            }

            ToggleButton {
                id: gameModeButton

                condition: WispState.gameMode
                label: "Game Mode"
                onToggled: (newValue) => WispState.gameMode = newValue
            }

        }

    }

}
