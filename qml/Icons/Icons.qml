// qml/Icons/Icons.qml

pragma Singleton

import QtQuick
import Quickshell

Singleton {

    readonly property string base: Quickshell.env("WISP_SHARE_DIR") + "/assets"
    readonly property string icons: base + "/icons"

    readonly property string mascot: base + "/wisp.svg"

    function getMascot() {
        return mascot
    }

    function getIcon(name) {
        return `${icons}/${name}.svg`
    }

}