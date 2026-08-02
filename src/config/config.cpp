// src/config/config.cpp

#include "config.hpp"

#include <cstdlib>
#include <fstream>
#include <iostream>

#include <nlohmann/json.hpp>

#include <../env.hpp>

namespace wisp::config {

namespace {

void exportEnv(const Config &cfg) {
    setenv(wisp::env::kTimeFormat, cfg.timeFormat.c_str(), 1);
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

    exportEnv(cfg);
    return cfg;
}

} // namespace wisp::config
