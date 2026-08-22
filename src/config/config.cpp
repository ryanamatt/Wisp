// src/config/config.cpp

#include "config.hpp"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <optional>

#include <nlohmann/json.hpp>

#include <env.hpp>

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
        if (!entry.is_object() || !entry.contains("name") || !entry["name"].is_string() ||
            !entry.contains("command") || !entry["command"].is_array()) {
            std::cerr << "wisp: skipping invalid appLauncher.apps entry (needs name + command)\n";
            continue;
        }

        AppEntry app;
        app.name = entry["name"].get<std::string>();

        for (const auto &part : entry["command"]) {
            if (part.is_string()) {
                app.command.push_back(part.get<std::string>());
            }
        }
        if (app.command.empty()) {
            std::cerr << "wisp: skipping appLauncher.apps entry \"" << app.name << "\": empty command\n";
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

void exportEnv(const Config &cfg) {
    setenv(wisp::env::kTimeFormat, cfg.timeFormat.c_str(), 1);
    setenv(wisp::env::kAppsJson, appsToJson(cfg.apps).c_str(), 1);
}

} // namespace

std::vector<AppEntry> defaultApps() {
    return {
        {"Chrome", {"google-chrome-stable"}, "google-chrome"},
        {"Discord", {"discord"}, "discord"},
        {"Spotify", {"spotify-launcher"}, "spotify-launcher"},
        {"VS Code", {"code"}, "vscode"},
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
        std::cerr << "wisp: failed to parse config at " << path << ": " << e.what() << "\n";
        std::cerr << "wisp: falling back to defaults\n";
        exportEnv(cfg);
        return cfg;
    }

    if (j.contains("bar") && j["bar"].is_object()) {
        const auto &bar = j["bar"];
        if (bar.contains("time-format")) {
            if (bar["time-format"].is_string())
                cfg.timeFormat = bar["time-format"].get<std::string>();
            
            else std::cerr << "wisp: bar.time-format must be a string, ignoring\n";
        }
    }

    if (auto apps = parseApps(j)) {
        cfg.apps = std::move(*apps);
    }

    exportEnv(cfg);
    return cfg;
}

} // namespace wisp::config
