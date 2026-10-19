// qml/bar/Action/ActionPopup.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"
import "../../Components"

BarPopup {
    id: root

    signal requestClose()
    property int currentIndex: 0

    function resetSelection() {
        root.currentIndex = 0
    }


}