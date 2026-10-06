// qml/OSD/OSDBase.qml

import QtQuick
import Quickshell

Scope {
    id: osdScope

    property string icon: ""
    property bool showBar: true
    property real barValue: 0
    property string valueText: ""

    // Prevents firing during startup when initial values settle
    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => _ready = true)

    signal requested()

    function show() {
        if (!_ready) return
        requested()
    }
}
