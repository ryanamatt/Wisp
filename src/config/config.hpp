// src/config/config.hpp

#pragma once

#include <string>
#include <vector>

namespace wisp::config {

// ---------------------------------------------------------------------
// Defaults live here and only here.
// ---------------------------------------------------------------------
inline constexpr const char *kDefaultTimeFormat = "ddd MMM d hh:mm:ss AP";

// One entry in the app launcher's grid.
struct AppEntry {
    std::string name;
    std::vector<std::string> command;
    std::string icon;
};

// The launcher's built-in app list, used whenever config.json has no
// (valid) appLauncher.apps array of its own.
std::vector<AppEntry> defaultApps();

struct Config {
    std::string timeFormat = kDefaultTimeFormat;
    std::vector<AppEntry> apps = defaultApps();
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
