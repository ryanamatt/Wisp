// src/logging/log.hpp

#pragma once

#include <string>

// Plain C++ logging core with no Qt dependency, so both the wisp
// supervisor process (main.cpp) and the QML-facing Logger singleton
// can share one implementation and one log file.

namespace wisp::log {

enum class Level { Debug, Info, Warning, Error };

void debug(const std::string &message);
void debug(const std::string &category, const std::string &message);

void info(const std::string &message);
void info(const std::string &category, const std::string &message);

void warning(const std::string &message);
void warning(const std::string &category, const std::string &message);

void error(const std::string &message);
void error(const std::string &category, const std::string &message);

// Path of the active log file. Opens the state directory and the file
// on first call if nothing has logged yet.
std::string filePath();

} // namespace wisp::log
