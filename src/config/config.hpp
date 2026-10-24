// src/config/config.hpp

#pragma once

#include <string>
#include <vector>

namespace wisp::config {

// ---------------------------------------------------------------------
// Defaults live here and only here.
// ---------------------------------------------------------------------
inline constexpr const char *kDefaultTimeFormat = "ddd MMM d hh:mm:ss AP";
inline constexpr const char *kDefaultBarOrientation = "top";
inline constexpr const char *kDefaultFont = "Noto Sans";
inline constexpr const char *kDefaultWallpaperSubdir = "Pictures/wallpapers"; // Relative to $HOME
inline constexpr bool kDefaultPackagesNotifyOnStartUp = false;
inline constexpr bool kDefaultPackagesNotifyEveryDay = false;
inline constexpr const int kDefaultBatteryWarnPerc = 30;
inline constexpr bool kDefaultBatteryAutoPowerSaver = false;
inline constexpr int kDefaultNotificationToastMs = 2000;

struct Config {
    std::string timeFormat = kDefaultTimeFormat;
    std::string barOrientation = kDefaultBarOrientation;
    std::string font = kDefaultFont;
    std::string wallpaperDir;
    bool packagesNotifyOnStartUp = kDefaultPackagesNotifyOnStartUp;
    bool packagesNotifyEveryDay = kDefaultPackagesNotifyEveryDay;
    int batteryWarnPerc = kDefaultBatteryWarnPerc;
    bool batteryAutoPowerSaver = kDefaultBatteryAutoPowerSaver;
    int notificationToastMs = kDefaultNotificationToastMs;
};

// Resolves the default config file location:
//   $XDG_CONFIG_HOME/wisp/config.json, falling back to
//   $HOME/.config/wisp/config.json.
// Returns an empty string if neither can be determined.
std::string defaultPath();

// Loads config from `path`. A missing file, missing keys, or a parse
// error all fall back to defaults rather than failing.
Config load(const std::string &path);

} // namespace wisp::config
