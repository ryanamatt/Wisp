// qml/shell.qml

import Quickshell
import "Bar"
import "ThemeSwitcher"
import "WorkspaceSwitcher"
import "CommandCenter"
import "Screenshot"
import "OSD"

Scope {
    Bar {}

    ThemeSwitcher {}

    WorkspaceSwitcher {}

    CommandCenter {}

    Screenshot {}

    OSDBrightness {}
    OSDVolume {}
}