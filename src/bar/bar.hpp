// src/bar/bar.hpp

#pragma once

#include <string>

// Runs wisp's bar by launching quickshell as a supervised child
// process. Blocks for the lifetime of the bar.
namespace wisp::bar {

int runBar(const std::string &qmlDir, const std::string &configPath, const std::string &modulePath);

} // namespace wisp::bar