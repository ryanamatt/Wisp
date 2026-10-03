// src/config/config.cpp

#include "config.hpp"

#include <cstdlib>
#include <fstream>
#include <optional>

#include <nlohmann/json.hpp>

#include <env.hpp>
#include <logging/log.hpp>

namespace wisp::config {

namespace {

// Serializes the app list back to JSON so it can be handed to the QML
// process via an environment variable.
std::string appsToJson(const std::vector<AppEntry> &apps) {
    nlohmann::json arr = nlohmann::json::array();
    for (const auto &app : apps) {
        arr.push_back({
            {"name", app.name},
            {"command", app.command},
            {"icon", app.icon},
        });
    }
    return arr.dump();
}

// Parses config["appLauncher"]["apps"] into a list of AppEntry. Returns
// std::nullopt if the key is absent, not an array, or every entry in
// it fails to parse -- callers should fall back to defaultApps().
std::optional<std::vector<AppEntry>> parseApps(const nlohmann::json &j) {
    if (!j.contains("appLauncher") || !j["appLauncher"].is_object()) return std::nullopt;

    const auto &launcher = j["appLauncher"];
    if (!launcher.contains("apps") || !launcher["apps"].is_array()) return std::nullopt;

    std::vector<AppEntry> apps;
    for (const auto &entry : launcher["apps"]) {
        if (!entry.is_object() || !entry.contains("name") || !entry["name"].is_string() || !entry.contains("command") ||
            !entry["command"].is_array()) {
            wisp::log::warning("config", "skipping invalid appLauncher.apps entry (needs name + command)");
            continue;
        }

        AppEntry app;
        app.name = entry["name"].get<std::string>();

        for (const auto &part : entry["command"]) {
            if (part.is_string()) { app.command.push_back(part.get<std::string>()); }
        }
        if (app.command.empty()) {
            wisp::log::warning("config", "skipping appLauncher.apps entry \"" + app.name + "\": empty command");
            continue;
        }

        // Icon is optional; falls back to an icon lookup by app name.
        if (entry.contains("icon") && entry["icon"].is_string()) {
            app.icon = entry["icon"].get<std::string>();
        } else {
            app.icon = app.name;
        }

        apps.push_back(std::move(app));
    }

    if (apps.empty()) return std::nullopt;
    return apps;
}

// Resolves the wallpaper directory to use.
std::string resolveWallpaperDir(const std::string &configured) {
    const char *home = std::getenv("HOME");

    if (configured.empty()) { return home && *home ? std::string(home) + "/" + kDefaultWallpaperSubdir : ""; }

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

void readInt(const nlohmann::json &j, const char *key, const std::string &label, int &out) {
    if (!j.contains(key)) return;
    if (j[key].is_number_integer())
        out = j[key].get<int>();
    else
        wisp::log::warning("config", label + " must be an int, ignoring");
}

void exportEnv(const Config &cfg) {
    setenv(wisp::env::kTimeFormat, cfg.timeFormat.c_str(), 1);
    setenv(wisp::env::kBarOrientation, cfg.barOrientation.c_str(), 1);
    setenv(wisp::env::kFont, cfg.font.c_str(), 1);
    setenv(wisp::env::kAppsJson, appsToJson(cfg.apps).c_str(), 1);
    setenv(wisp::env::kWallpaperDir, cfg.wallpaperDir.c_str(), 1);
    setenv(wisp::env::kPackagesNotifyOnStartUp, cfg.packagesNotifyOnStartUp ? "true" : "false", 1);
    setenv(wisp::env::kPackagesNotifyEveryDay, cfg.packagesNotifyEveryDay ? "true" : "false", 1);
    setenv(wisp::env::kBatteryWarnPerc, std::to_string(cfg.batteryWarnPerc).c_str(), 1);
    setenv(wisp::env::kBatteryAutoPowerSaver, cfg.batteryAutoPowerSaver ? "true" : "false", 1);
}

} // namespace

std::vector<AppEntry> defaultApps() {
    return {
        {"Chrome", {"google-chrome-stable"}, "google-chrome"}, {"Discord", {"discord"}, "discord"},
        {"Spotify", {"spotify-launcher"}, "spotify-launcher"}, {"VS Code", {"code"}, "vscode"},
        {"Dolphin", {"dolphin"}, "org.kde.dolphin"},
    };
}

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
    Config cfg;
    cfg.wallpaperDir = resolveWallpaperDir("");

    std::ifstream in(path);
    if (!in.is_open()) {
        // No config file present -- not an error, just run with defaults.
        exportEnv(cfg);
        return cfg;
    }

    nlohmann::json j;
    try {
        in >> j;
    } catch (const nlohmann::json::parse_error &e) {
        wisp::log::error("config", "failed to parse config at " + path + ": " + e.what());
        wisp::log::info("config", "falling back to defaults");
        exportEnv(cfg);
        return cfg;
    }

    if (j.contains("bar") && j["bar"].is_object()) {
        const auto &bar = j["bar"];
        if (bar.contains("timeFormat")) {
            if (bar["timeFormat"].is_string())
                cfg.timeFormat = bar["timeFormat"].get<std::string>();
            else
                wisp::log::warning("config", "bar.timeFormat must be a string, ignoring");
        }

        if (bar.contains("orientation")) {
            if (bar["orientation"].is_string())
                cfg.barOrientation = bar["orientation"].get<std::string>();
            else
                wisp::log::warning("config", "bar.orientation must be a string, ignoring");
        }
    }

    if (j.contains("font")) {
        if (j["font"].is_string())
            cfg.font = j["font"].get<std::string>();
        else
            wisp::log::warning("config", "font must be a string, ignoring");
    }

    if (j.contains("wallpaper") && j["wallpaper"].is_object()) {
        const auto &wallpaper = j["wallpaper"];
        if (wallpaper.contains("directory")) {
            if (wallpaper["directory"].is_string())
                cfg.wallpaperDir = resolveWallpaperDir(wallpaper["directory"].get<std::string>());
            else
                wisp::log::warning("config", "wallpaper.directory must be a string, ignoring");
        }
    }

    if (j.contains("packages") && j["packages"].is_object()) {
        const auto &packages = j["packages"];
        readBool(packages, "notifyOnStartUp", "packages.notifyOnStartUp", cfg.packagesNotifyOnStartUp);
        readBool(packages, "notifyEveryDay", "packages.notifyEveryDay", cfg.packagesNotifyEveryDay);
    }

    if (j.contains("battery") && j["battery"].is_object()) {
        const auto &battery = j["battery"];
        readInt(battery, "warnPercentage", "battery.warnPercentage", cfg.batteryWarnPerc); // <-- Updated key name
        readBool(battery, "autoPowerSaver", "battery.autoPowerSaver", cfg.batteryAutoPowerSaver);
    }
 
    if (auto apps = parseApps(j)) { cfg.apps = std::move(*apps); }

    exportEnv(cfg);
    return cfg;
}

} // namespace wisp::config
