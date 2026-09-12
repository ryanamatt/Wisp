// src/cli/logCommand.cpp

#include "cli/logCommand.hpp"

#include <algorithm>
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <unistd.h>
#include <vector>

#include "logging/log.hpp"

namespace wisp::cli {

int runLogCommand(LogCommand logCommand, int logNum) {
    std::filesystem::path logPath;
    if (const char *xdgState = std::getenv("XDG_STATE_HOME"); xdgState && *xdgState)
        logPath = std::filesystem::path(xdgState) / "wisp" / "wisp.log";
    else if (const char *home = std::getenv("HOME"); home && *home)
        logPath = std::filesystem::path(home) / ".local" / "state" / "wisp" / "wisp.log";
    else {
        std::cerr << "wisp: unable to determine home or state directory for log path\n";
        return 1;
    }

    if (logCommand == LogCommand::Clear) {
        std::ofstream logFile(logPath, std::ios::trunc);
        if (!logFile) {
            std::cerr << "wisp: could not clear log file at " << logPath << ": " << std::strerror(errno) << "\n";
            return 1;
        }
        std::cout << "wisp: cleared log file\n";
        return 0;
    }

    std::ifstream logFile(logPath);
    if (!logFile) {
        std::cerr << "wisp: could not open log file at " << logPath << ": " << std::strerror(errno) << "\n";
        return 1;
    }

    // Only colorize when writing straight to a terminal, so piping
    // `wisp log` into grep/less/a file doesn't get littered with
    // escape codes.
    const bool colorize = isatty(fileno(stdout));

    std::vector<std::string> lines;
    std::string line;
    while (std::getline(logFile, line)) { lines.push_back(line); }

    size_t start = 0;
    size_t end = lines.size();

    if (logCommand == LogCommand::Head)
        end = std::min(size_t(logNum), lines.size());
    else if (logCommand == LogCommand::Tail) {
        if (lines.size() > logNum) start = lines.size() - logNum;
    }

    for (size_t i = start; i < end; ++i) {
        const std::string &l = lines[i];
        std::cout << (colorize ? wisp::log::colorizeLine(l) : l) << "\n";
    }

    return 0;
}

} // namespace wisp::cli