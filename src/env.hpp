// include/wisp/env.hpp

#pragma once

// Names of the environment variables wisp uses to hand resolved
// config values from the main process.

namespace wisp::env {

// Config
inline constexpr const char *kTimeFormat = "WISP_TIME_FORMAT";
inline constexpr const char *kBarOrientation = "WISP_BAR_ORIENTATION";
inline constexpr const char *kFont = "WISP_FONT";
inline constexpr const char *kAppsJson = "WISP_APPS_JSON";
inline constexpr const char *kWallpaperDir = "WISP_WALLPAPER_DIR";
inline constexpr const char *kPackagesNotifyOnStartUp = "WISP_PACKAGES_NOTIFY_ON_STARTUP";
inline constexpr const char *kPackagesNotifyEveryDay = "WISP_PACKAGES_NOTIFY_EVERY_DAY";
inline constexpr const char *kBatteryWarnPerc = "WISP_BATTERY_WARN_PERC";

// Other
inline constexpr const char *kShareDir = "WISP_SHARE_DIR";

} // namespace wisp::env
