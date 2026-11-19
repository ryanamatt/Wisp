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

inline constexpr bool KDefaultGetWeatherFromIp = false;
inline constexpr const char *kDefaultWeatherCity = "";

inline constexpr const char *kDefaultWallpaperSubdir = "Pictures/wallpapers"; // Relative to $HOME
inline constexpr bool kDefaultRunMatugen = false;

inline constexpr bool kDefaultPackagesNotifyOnStartUp = false;
inline constexpr bool kDefaultPackagesNotifyEveryDay = false;

inline constexpr const int kDefaultBatteryWarnPerc = 30;
inline constexpr bool kDefaultBatteryAutoPowerSaver = false;

inline constexpr int kDefaultNotificationToastMs = 2000;

inline constexpr const char *kDefaultJokesFile = "jokes.txt"; // Relative to $HOME/.config/wisp

inline constexpr int kDefaultOSDDuration = 1000; // milliseconds
inline constexpr const char *kDefaultOSDOrientation = "bottom";
inline constexpr double kDefaultOSDScaleSize = 1.0;

struct Config {
    std::string timeFormat = kDefaultTimeFormat;
    std::string barOrientation = kDefaultBarOrientation;
    std::string font = kDefaultFont;
    bool getWeatherFromIp = KDefaultGetWeatherFromIp;
    std::string weatherCity = kDefaultWeatherCity;
    std::string wallpaperDir;
    bool runMatguen = kDefaultRunMatugen;
    bool packagesNotifyOnStartUp = kDefaultPackagesNotifyOnStartUp;
    bool packagesNotifyEveryDay = kDefaultPackagesNotifyEveryDay;
    int batteryWarnPerc = kDefaultBatteryWarnPerc;
    bool batteryAutoPowerSaver = kDefaultBatteryAutoPowerSaver;
    int notificationToastMs = kDefaultNotificationToastMs;
    std::string jokesFile = kDefaultJokesFile;
    int osdDuration = kDefaultOSDDuration;
    std::string osdOrientation = kDefaultOSDOrientation;
    double osdScaleSize = kDefaultOSDScaleSize;
};

// Resolves the default config file location:
//   $XDG_CONFIG_HOME/wisp/config.json, falling back to
//   $HOME/.config/wisp/config.json.
// Returns an empty string if neither can be determined.
std::string defaultPath();

// Resolves the default colors file location: colors.json in the same
// directory as the default config.json. Returns an empty string if
// that directory cannot be determined.
std::string defaultColorsPath();

// Loads config from `path`. A missing file, missing keys, or a parse
// error all fall back to defaults rather than failing.
Config load(const std::string &path);

} // namespace wisp::config
