// src/config/config.cpp

#include "config.hpp"

#include <cmath>
#include <cstdlib>
#include <fstream>
#include <limits>
#include <optional>

#include <nlohmann/json.hpp>

#include <env.hpp>
#include <logging/log.hpp>

namespace wisp::config {

namespace {

// Resolves a file or directory path, expanding '~' and falling back to defaultPath if empty.
std::string resolvePath(const std::string &configured, const std::string &defaultPath) {
    const char *home = std::getenv("HOME");

    if (configured.empty()) { return defaultPath; }

    if (configured == "~") { return home && *home ? std::string(home) : configured; }
    if (configured.rfind("~/", 0) == 0) {
        return home && *home ? std::string(home) + configured.substr(1) : configured;
    }

    return configured;
}

// Reads j[key] into `out` if it is a boolean. Otherwise warns and leaves
// `out` untouched. `label` is the dotted config path used in the warning.
void readBool(const nlohmann::json &j, const char *key, const std::string &label, bool &out) {
    if (!j.contains(key)) return;
    if (j[key].is_boolean())
        out = j[key].get<bool>();
    else
        wisp::log::warning("config", label + " must be a boolean, ignoring");
}

void readInt(const nlohmann::json &j, const char *key, const std::string &label, int &out, int min, int max) {
    if (!j.contains(key)) return;
    if (!j[key].is_number_integer()) {
        wisp::log::warning("config", label + " must be an int, ignoring");
        return;
    }
    const double value = j[key].get<double>();
    if (value < min || value > max) {
        wisp::log::warning("config", label + " must be between " + std::to_string(min) + " and " + std::to_string(max) +
                                         ", ignoring");
        return;
    }
    out = static_cast<int>(value);
}

void readDouble(const nlohmann::json &j, const char *key, const std::string &label, double &out, double min,
                double max) {
    if (!j.contains(key)) return;
    if (!j[key].is_number()) {
        wisp::log::warning("config", label + " must be a number, ignoring");
        return;
    }
    const double value = j[key].get<double>();
    if (value < min || value > max) {
        wisp::log::warning("config", label + " must be written between " + std::to_string(min) + " and " +
                                         std::to_string(max) + ", ignoring");
        return;
    }
    out = value;
}

void readStr(const nlohmann::json &j, const char *key, const std::string &label, std::string &out) {
    if (!j.contains(key)) return;
    if (!j[key].is_string()) {
        wisp::log::warning("config", label + " must be a string, ignoring");
        return;
    }
    const std::string value = j[key].get<std::string>();
    out = value;
}

void readPath(const nlohmann::json &j, const char *key, const std::string &label, std::string &out,
              const std::string &defaultPath) {
    if (!j.contains(key)) return;
    if (!j[key].is_string()) {
        wisp::log::warning("config", label + " must be a string, ignoring");
        return;
    }
    const std::string value = j[key].get<std::string>();
    out = resolvePath(value, defaultPath);
}

void exportEnv(const Config &cfg, const std::string &path) {
    setenv(wisp::env::kConfigPath, path.c_str(), 1);
    setenv(wisp::env::kTimeFormat, cfg.timeFormat.c_str(), 1);
    setenv(wisp::env::kBarOrientation, cfg.barOrientation.c_str(), 1);
    setenv(wisp::env::kFont, cfg.font.c_str(), 1);
    setenv(wisp::env::kWallpaperDir, cfg.wallpaperDir.c_str(), 1);
    setenv(wisp::env::kPackagesNotifyOnStartUp, cfg.packagesNotifyOnStartUp ? "true" : "false", 1);
    setenv(wisp::env::kPackagesNotifyEveryDay, cfg.packagesNotifyEveryDay ? "true" : "false", 1);
    setenv(wisp::env::kBatteryWarnPerc, std::to_string(cfg.batteryWarnPerc).c_str(), 1);
    setenv(wisp::env::kBatteryAutoPowerSaver, cfg.batteryAutoPowerSaver ? "true" : "false", 1);
    setenv(wisp::env::kNotificationToastMs, std::to_string(cfg.notificationToastMs).c_str(), 1);
    setenv(wisp::env::kJokesFile, cfg.jokesFile.c_str(), 1);
    setenv(wisp::env::kOSDDuration, std::to_string(cfg.osdDuration).c_str(), 1);
    setenv(wisp::env::kOSDOrientation, cfg.osdOrientation.c_str(), 1);
    setenv(wisp::env::kOSDScaleSize, std::to_string(cfg.osdScaleSize).c_str(), 1);
}

} // namespace

std::string defaultPath() {
    if (const char *xdgConfig = std::getenv("XDG_CONFIG_HOME"); xdgConfig && *xdgConfig) {
        return std::string(xdgConfig) + "/wisp/config.json";
    }
    if (const char *home = std::getenv("HOME"); home && *home) {
        return std::string(home) + "/.config/wisp/config.json";
    }
    return "";
}

Config load(const std::string &path) {
    const char *home = std::getenv("HOME");
    const std::string defaultWallpaper = home && *home ? std::string(home) + "/" + kDefaultWallpaperSubdir : "";
    const std::string defaultJokes = home && *home ? std::string(home) + "/.config/wisp/" + kDefaultJokesFile : "";

    Config cfg;
    cfg.wallpaperDir = resolvePath("", defaultWallpaper);
    cfg.jokesFile = resolvePath("", defaultJokes);

    std::ifstream in(path);
    if (!in.is_open()) {
        // No config file present -- not an error, just run with defaults.
        exportEnv(cfg, path);
        return cfg;
    }

    nlohmann::json j;
    try {
        in >> j;
    } catch (const nlohmann::json::parse_error &e) {
        wisp::log::error("config", "failed to parse config at " + path + ": " + e.what());
        wisp::log::info("config", "falling back to defaults");
        exportEnv(cfg, path);
        return cfg;
    }

    if (j.contains("bar") && j["bar"].is_object()) {
        const auto &bar = j["bar"];
        readStr(bar, "timeFormat", "bar.timeFormat", cfg.timeFormat);
        readStr(bar, "orientation", "bar.orientation", cfg.barOrientation);
    }

    readStr(j, "font", "font", cfg.font);

    if (j.contains("wallpaper") && j["wallpaper"].is_object()) {
        const auto &wallpaper = j["wallpaper"];
        readPath(wallpaper, "directory", "wallpaper.directory", cfg.wallpaperDir, defaultWallpaper);
    }

    if (j.contains("packages") && j["packages"].is_object()) {
        const auto &packages = j["packages"];
        readBool(packages, "notifyOnStartUp", "packages.notifyOnStartUp", cfg.packagesNotifyOnStartUp);
        readBool(packages, "notifyEveryDay", "packages.notifyEveryDay", cfg.packagesNotifyEveryDay);
    }

    if (j.contains("battery") && j["battery"].is_object()) {
        const auto &battery = j["battery"];
        readInt(battery, "warnPercentage", "battery.warnPercentage", cfg.batteryWarnPerc, 0, 100);
        readBool(battery, "autoPowerSaver", "battery.autoPowerSaver", cfg.batteryAutoPowerSaver);
    }

    if (j.contains("notifications") && j["notifications"].is_object()) {
        const auto &notifications = j["notifications"];
        readInt(notifications, "toastDurationMs", "notifications.toastDurationMs", cfg.notificationToastMs, 500, 60000);
    }

    if (j.contains("welcome") && j["welcome"].is_object()) {
        const auto &welcome = j["welcome"];
        readPath(welcome, "jokesFile", "welcome.jokesFile", cfg.jokesFile, defaultJokes);
    }

    if (j.contains("osd") && j["osd"].is_object()) {
        const auto &osd = j["osd"];
        readInt(osd, "duration", "osd.duration", cfg.osdDuration, 0, std::numeric_limits<int>::max());
        readStr(osd, "orientation", "osd.orientation", cfg.osdOrientation);
        readDouble(osd, "scaleSize", "osd.scaleSize", cfg.osdScaleSize, 0.0f, 4.0f);
    }

    exportEnv(cfg, path);
    return cfg;
}

} // namespace wisp::config
