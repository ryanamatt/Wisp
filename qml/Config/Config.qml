// qml/Config/Config.qml

pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: config

    property string font: Quickshell.env("WISP_FONT") || "Noto Sans";

}