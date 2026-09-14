// qml/Icons/Icons.qml

pragma Singleton

import QtQuick
import Quickshell

Singleton {

    readonly property string base: Quickshell.env("WISP_SHARE_DIR") + "/assets/icons"

    function getIcon(name) {
        return `${base}/${name}.svg`
    }

}