// src/config/config.hpp

#pragma once

#include <string>

namespace wisp::config {

// ---------------------------------------------------------------------
// Defaults live here and only here.
// ---------------------------------------------------------------------
inline constexpr const char *kDefaultTimeFormat = "ddd MMM d hh:mm:ss AP";

struct Config {
    std::string timeFormat = kDefaultTimeFormat;
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
