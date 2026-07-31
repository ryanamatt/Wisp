# **Hyprland Top-Bar Layout (1920px)**

## Plan

Use this grid to map out your widgets. Each character represents a unit of space.

Current Layout:

A SM WE BT P TTTT W VVV C TS N

Legend:

* A: App Launcher (Far left, trigger: SUPER \+ SPACE)  
* SM: System Monitor (CPU/RAM, detailed hover)  
* WE: WIFI/Ethernet Status  
* BT: Bluetooth Status  
* P: Power Button (Drops power menu)  
* T: Time/Date (Centered, hover for Google Calendar)  
* O: Workspace Indicator (Underneath Time, 5 ovals)  
* W: Small Weather Indicator (Drops down to show more info)  
* V: Audio Visualizer (Right of Time, hover for Mpris player/controls)  
* C: Clipboard Manager (Small button)  
* TS: Theme Switcher (Small button)  
* N: SwayNC Notification Center trigger (Far right)  
* X: Empty space

Notes:

* Total width: 1920 pixels.  
* The Time widget handles the calendar popup logic.  
* Workspace Indicator is an overlay/underlay below the Time.


## Current Workings

1920 - 200 - 75 
1645 px left of screen real estate.

Left Side (960 - 100 - 75 = 785): 
75 px - App Launcher

Space

100 px - Time 

Right Side (960 - 100 = 860):
100px - Time

Space