# Wisp Features

This Document outlines every single Feature that Wisp can do.
This Document does not outline how things are done.
This Document is kept in line with what is in master.

## Table of Contents

- **[CLI](#cli)**
  - *[run](#run)*
  - *[kill](#kill)*
  - *[reload](#reload)*
  - *[log](#log)*
  - *[status](#status)*
  - *[open](#open)*
  - *[close](#close)*
  - *[toggle](#toggle)*
  - *[targets](#targets)*
  - *[lock](#lock)*
  - *[flags](#flags)*
- **[Bar](#bar)**
  - *[Action Widget](#action-widget)*
  - *[System Monitor Widget](#system-monitor-widget)*
  - *[Network Widget](#network-widget)*
  - *[Brightness Widget](#brightness-widget)*
  - *[Battery Widget](#battery-widget)*
  - *[Power Menu Widget](#power-menu-widget)*
  - *[Time/Workspace Widget](#timeworkspace-widget)*
  - *[Weather Widget](#weather-widget)*
  - *[Audio Widget](#audio-widget)*
  - *[Clipboard Widget](#clipboard-widget)*
  - *[Notifications Widget](#notifications-widget)*
- **[Command Center](#command-center)**
  - *[Welcome Section](#welcome-section)*
  - *[System Section](#system-section)*
  - *[Packages Section](#packages-section)*
  - *[Settings Section](#settings-section)*
- **[Runner](#runner)**
  - *[App Launching](#app-launching)*
  - *[Calculator Mode](#calculator-mode)*
  - *[Command Mode](#command-mode)*
  - *[Symbol Mode](#symbol-mode)*
- **[OSD](#osd)**
  - *[Volume OSD](#volume-osd)*
  - *[Mic OSD](#mic-osd)*
  - *[Brightness OSD](#brightness-osd)*
  - *[Caps Lock OSD](#caps-lock-osd)*
  - *[Num Lock OSD](#num-lock-osd)*
  - *[Charging OSD](#charging-osd)*
- **[Workspace Switcher](#workspace-switcher)**
- **[Theme Switcher](#theme-switcher)**
- **[Window Rules](#window-rules)**
- **[Screenshot](#screenshot)**
  - *[Screenshot Tab](#screenshot-tab)*
  - *[Video Tab](#video-tab)*
- **[Timer](#timer)**
  - *[Timer Tab](#timer-tab)*
  - *[Stopwatch Tab](#stopwatch-tab)*
- **[Lock Screen](#lock-screen)**

## **CLI**

### *Run*

This Command is what runs Wisp. It Spawns Quickshell as a subprocess and 
launches the bar.

### Kill

Kills the current Wisp Process that is running.

### Reload

Reloads the Quickshell Process of a running Wisp Process. Also re-reads the 
config.json file reloading the configs.

### Log

Log prints the log file (located at ~/.local/state/wisp/wisp.log) to the 
terminal in color.

```bash
wisp log

wisp log [head|tail] [n]
wisp log clear
```

Log has several Sub Commands (Default `tail 15`):

#### Head

Prints the head of with the first n lines. If n not provided defaults to 15.

```bash
wisp log head 10
```

#### Tail

Prints the tail of the last n lines of the log file. If n not provided defaults 
to 15.

```bash
wisp log tail 20
```

#### Clear

Clears the log file of any content.

```bash
wisp log clear
```

### Status

Prints the status of the current running Wisp Process.
Shows if it is running, the version currently running, the commit of the 
version that is currently running, its PID, its uptime, and the config file.

```bash
wisp status
```

### Open

Sends the `Open` IPC Command to a target. `Open` opens a Window or Bar Popup.
See [Targets](targets) for list of targets.

```bash
wisp open <target>

# Ex.
wisp open themeSwitcher
```

### Close

Sends the `Close` IPC Command to a target. `Close` closes a Window or Bar Popup
See [Targets](targets) for list of targets.

```bash
wisp close <target>

# Ex.
wisp close themeSwitcher
```

### Toggle

Sends the `Toggle` IPC Command to a target. Toggle sends `Close` if the window
or Bar Poup is open and `Open` if the Window or Bar Popup is closed.
See [Targets](targets) for list of targets.

```bash
wisp toggle <target>

# Ex.
wisp toggle themeSwitcher
```

### Targets

Lists all targets for which Open, Close, and Toggle commands can hit.

```bash
wisp targets
```

### Lock

Sends the Lock IPC Command. This will put up the Lock Screen
See [Lock Screen](#lock-screen) for more info about the Lock Screen itself.

```bash
wisp lock
```

### Flags

#### d Flag

This Flag disowns the command and immediately returns control of the terminal.

```bash
wisp -d run
# or
wisp run -d
```

#### f Flag

This flag sets where wisp will look for the Quickshell shell.qml file. 
Default is the installed location: /usr/share/wisp/qml.

```bash
wisp -f /path/to/shell.qml run
```

#### m Flag

This flag sets the location where Wisp will look for the directory of backend 
modules.
Default is the installed location: /usr/share/wisp/qml/Wisp

```bash
wisp -m /path/to/backend/modules run
```

#### c Flag

This Flags sets the path where Wisp will look for its config.json file.
Default is $XDG_CONFIG_HOME/wisp/config.json, if XDG_CONFIG_HOME else it is
/home/$USER/.config/wisp/config.json

```bash
wisp -c /path/to/config.json run
```

## **Bar**

The Bar sits at the Top or Bottom of the Screen. The bar has 11 Widgets to 
interact with. These Widgets are hardcoded in place and appear in order
from left to right below. 

Almost every Widget, has an associated popup. This popup can be opened by
hovering your cursor over the widget or by doing: `wisp toggle <target>`.

### Action Widget

The Action Widget is the home of any Wisp Actions.

Its popup contains:
- A Toggle Button here to turn on/off Game Mode.

### System Monitor Widget

The System Monitor Widget contains information about the current system.
The Widget itself instead of an icons shows your CPU Temp in Celsius as well
as the CPU Usage.

Its popup contains:
- Text for Rx (Recieve) and Tx (transmit) values.
- Text for Name, Temperature, Usage Bar, Usage % for CPU and GPU
- Text for Memory and Each Parition showing how much space it takes up out of total.

### Network Widget

The network Widget is the home for Network Connection.

Its popup contains:
- Shows your current connection at the top.
- Shows a button to toggle on/off wifi and to rescan for wifi networks.
- Shows a list of available networks, their strength and if they require a password via icons.
- If clicked on availble network tries to connect or prompts a password.

> Known Limitations: Only works with simple password, anything else is not covered.

### Brightness Widget

The Brightness Widget handles the Brightness of your screen, nightlight, and keyboard.

Its popup contains:
- Drag Bar to change brightness. If Screen has changeable brightness
- A Toggle Button to toggle on/off the nightlight (hyprsunset). 
  - If Toggled, shows a new drag bar for setting temperature.
- If hardware has keyboard backlight, a drag bar is visible for changing its value.

### Battery Widget

The Battery Widget shows the battery of your system (if applicable) or
a razer accessory or headsetcontrol accessory. It will swap between them
with a icon denoting each.

Its Popup Shows:
- A list of all accesories and laptop batter percentage.
- 3 Buttons at the bottom to change your power profile.

### Power Menu Widget

The Power Menu Widget is where you Lock, Sleep Log out, Reboot, Shut Down

Its Popup Shows:
- 5 Button Row with Lock, Sleep, Log Out, Reboot, Shutdown.
  - Once Clicked or Press Enter requires a second confirmation (click) before running command.

### Time/Workspace Widget

This Widget shows the time of the day. Below the time is 5 ovals indicating
workspace 1-5 (or 6-10) on the current workspace. The workspace currently showing
is in an accent color. If a Workspace not 1-10 a 6th oval appears to the left
showing the first char of that workspace.

Its Popup shows:
  - A Calendar of the current Month on the left
  - Upcoming Events from `gcalcli`

### Weather Widget

The Weather Widget is the home of weather using the `Open Meteo API`. The 
Weather widget shows the current temperature in Fahrenheit along side
an icon dictating the current weather (sunny, cloudy, snowing, etc.).

There is no Popup for the Weather Widget.

### Audio Widget

The Audio Widget is where basic Audio Controls can be found. It's widget shows
a `cava` audio visualizer as its icon.

Its Popup shows:
  - A Microphone Control
    - Button to toggle muting mic
    - Drag bar to change Mic Volume
  - A Volume Control
    - Button to toggle muting the volume
    - Drag bar to change the volume
  - A Visual of the Art provided by MPRIS. If not art, shows an Album Icon.
  - Usage Bar showing how far along in the MPRIS media you are.
  - Buttons for Previous, Pause/Play, and Next in the MPRIS player.

### Clipboard Widget

The clipboard Widget is where you can acess your clipboard history via `wl-clipboard`.

Its Popup shows:
  - A search bar to search through your clipboard history
  - A Toggle Button whether or not it should be saving your clipboard history.
  - A Button to Clear Entire Clipboard History. 1 Press to changes to confirm,
  2nd press actually does it.
  - A list of your clipboard items (shows actual Images as Images) with an individual
  x button to remove just that item from clipboard history.

### Notifications Widget

The Notifications Widget is where you can access notifications.

Its Popup Shows:
  - A button to toggle Do not Disturb.
  - A Button to clear all notifications. 1 Press asks confirm, 2nd Press actually clears.
  - A List of all your notifications with an x button to delete just that notifications

## **Command Center**

The Command Center is the central control unit of Wisp. It handles many things.
The Command Center has many sections shown on the left with the body of each 
section being on the right. 
Use Shift + Up/Down to move between Sections.

### Welcome Section

The Welcome Section is the default section for the Command Center.
It shows a welcome message with the Wisp Will-o-Wisp Mascot floating.
It also shows a joke from the jokes file which you can set.

### System Section

The System Section shows you in depth Monitoring of your system.
It shows your uptime and load.
It shows your GPU, CPU and RAM on nice looking Gauges.
Shows a graph of your Rx and Tx network over time.
Shows each parition on the system in a nice lookig gauge.

### Packages Section

The Packages Section is where you can see what packages you need updating.
Uses `yay` and `flatpak`. It shows 2 sections: Packages from yay for Arch and form the AUR; and your packages from flatpak. There is a big button to run upkeep in kitty. Pressing this button will open a kitty terminal and run a script to upkeep your system. This script updates yay, flatpak, removes orphans in both and removes caches in both.

### Settings Section

The Settings Section is a GUI for your Config. In this section
you are able to update each of your configurations. There is a big
save button which will save your Settings by overwriting your
config file.

## **Runner**

The Runner is where you are able to launch apps, do basic calculator stuff, and find symbols. The  Runner works by changing modes based on
the first character typed.

### App Launching

App Launching is the default behavior of the Runner. It only works
if there is no special character to change modes.
Type to Search for your apps.
Most used Apps are shown first.
Use Arrows Keys and Enter to select your app.

### Calculator Mode

To change into calculator mode, type `=` and ensure it is your first character. Then type an equation. The window will extend to show your awnser.

Examples:
```runner
=10+2
=2sin(10)
=pi + 2
=sqrt(4)
```

### Command Mode

To change into command mode, type `>` as your first character.
Then type whatever you want to shell out to bash.

Examples:
```bash
> notify-send "Hello World"
```

### Symbol Mode

To change into symbol mode, type `:` as your fist character.
Then the window will expand to show all available emojis
and symbols. Continue typing to search for what you want.

Examples:
```runner
:happy
:thumbs up
```

## **OSD**

On Screen Displays (OSD) are little windows that show up upon the change of a certain value. OSD's each contain an Icon of what changed, a usage bar (if applicable) and the new value.

### Volume OSD

This OSD shows the new volume upon volume value being changed.

### Mic OSD

This OSD shows the new mic value upon mic value being changed.

### Brightness OSD

This OSD shows the new brightness value upon brightness value being changed.

### Caps Lock OSD

This OSD shows the new Caps Lock value upon caps lock value being changed.

### Num Lock OSD

This OSD shows the new Num Lock value upon num lock value being changed.

### Charging OSD

This OSD shows the Battery Item's battery upon said item being
plugged in. See [Battery Widget](#battery-widget) for more info on the devices being checked here.

## **Theme Switcher**

The theme Switcher is a new Window where you can change your wallpaper and therefore theme. It shows you a gallery of wallpapers from your wallpaper directory path and once selected runs `awww` and `matugen` to
update your theme. It also runs `razer-cli` to update your razer accessories (does not run if no `razer-cli` on path).

## **Workspace Switcher**

Shows a Rolodex of your occupied workspaces. Allows you go through with
each card showing you an icon of what windows are open on the workspace.
Pressing Enter or Left Clicking takes you to that workspace.

## **Screenshot**

The Screenshot Window allows you to take Screenshots.

### Screenshot Tab

The Screenshot Tab has a toggle button to toggle saving to Disk. 
Then there are 3 buttons to take screenshots: region, window and monitor.
Screenshots always copy to clipboard. 

### Video Tab

Not Available Yet.

## **Timer**

The Timer Window allows you to time things and use a Stopwatch.

### Timer Tab

This Tab is for timing things. Click the time to set how long you want
the timer to go. Press Enter to Confirm your time. Press Enter to start
the timer or press the Start button. THere is a Stop button which stops the timer and a pause button to pause the timer. Upob completion of timer
sends notification and plays a sound.

### Stopwatch Tab

The Stopwatch Time allows to run a stopwatch. Press start to start
the stopwatch. Buttons for Pause and Lap. May reset Stopwatch if it is 
paused on the reset button.

## **Window Rules**

The Window Rules Window shows you all the rules/properties of your current
hyprland window.

## **Lock Screen**

Lock Screen is what shows up when you lock.
Press any key to start typing your password which will cause a password
field to show up. It shows a blurred image of your screen with the time
and if applicable your battery life.
