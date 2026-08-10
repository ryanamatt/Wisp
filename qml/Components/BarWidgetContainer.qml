// qml/Components/BarWidgetContainer.qml

import QtQuick
import Quickshell.Hyprland
import "../Colors"

Rectangle {
    id: container

    color: Colors.colors.backgroundAlt
    border.color: Colors.colors.background
    border.width: 2

    implicitHeight: 36

    default property alias content: container.data

    property alias icon: icon

    // ----- Open/close progress -----
    // Bind isOpenHere to whatever condition means "my popup is the one
    // currently open" (this differs per widget, e.g. comparing against
    // GlobalState screen/open flags).
    property bool isOpenHere: false

    property real openProgress: isOpenHere ? 1 : 0
    Behavior on openProgress {
        SpringAnimation { spring: 3.2; damping: 0.32; epsilon: 0.001 }
    }

    // Pill is fully round while closed. the bottom corners flatten as the
    // popup opens so the pill and popup beneath it read as one shape.
    readonly property real fullRadius: implicitHeight / 2
    topLeftRadius: fullRadius
    topRightRadius: fullRadius
    bottomLeftRadius: fullRadius * (1 - openProgress)
    bottomRightRadius: fullRadius * (1 - openProgress)

    // ----- Hover-to-open / delayed-close -----
    signal requestOpen()
    signal requestClose()

    property int closeDelay: 200
    Timer {
        id: hideTimer
        interval: container.closeDelay
        onTriggered: container.requestClose()
    }

    function cancelClose() { hideTimer.stop() }
    function scheduleClose() { hideTimer.start() }

    // Call from any hover source (the widget pill itself, or its popup) to
    // keep things open; call close() once that source stops hovering.
    function open() {
        cancelClose()
        requestOpen()
    }
    function close() {
        scheduleClose()
    }
    // Closes immediately, bypassing the delay (e.g. focus grab cleared, or
    // the popup itself asked to close).
    function forceClose() {
        cancelClose()
        requestClose()
    }

    MouseArea {
        id: widgetHoverArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: container.open()
        onExited: container.close()
    }

    // ----- Focus grab -----
    // The owning widget activates/releases this explicitly (after moving
    // focus into the popup itself) so ordering against forceActiveFocus()
    // stays correct.
    property var popupWindows: []

    HyprlandFocusGrab {
        id: focusGrab
        windows: container.popupWindows
        onCleared: container.forceClose()
    }

    function activateFocusGrab() { focusGrab.active = true }
    function releaseFocusGrab() { focusGrab.active = false }

    Text {
        id: icon
        anchors.centerIn: parent
        color: Colors.colors.foreground
        font.pixelSize: 30
        font.family: "Noto Sans Mono"
    }

}
