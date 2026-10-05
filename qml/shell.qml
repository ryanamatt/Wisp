// qml/shell.qml

import Quickshell
import "Notifiers"
import "Bar"
import "ThemeSwitcher"
import "WorkspaceSwitcher"
import "CommandCenter"
import "Screenshot"
import "Runner"
import "Timer"
import "LockScreen"
import "OSD"

Scope {
    PackageNotifier {}

    Bar {}

    ThemeSwitcher {}

    WorkspaceSwitcher {}

    CommandCenter {}

    Screenshot {}

    Runner {}

    Timer {}

    LockScreen {}

    OSDManager {}
}
