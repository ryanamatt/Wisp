// qml/shell.qml

//@ pragma IconTheme breeze

import Quickshell
import "Notifiers"
import "Notifications"
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

    NotificationToasts {}

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
