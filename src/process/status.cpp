// src/process/status.cpp

#include "process/status.hpp"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <sstream>
#include <string>
#include <unistd.h>
#include <vector>

#include "config/config.hpp"
#include "process/pidfile.hpp"
#include "version.hpp"

namespace wisp::process {

namespace {

// Process uptime = system uptime - process start time. Start time is
// field 22 of /proc/<pid>/stat, in clock ticks since boot.
std::optional<long long> processUptimeSeconds(pid_t pid) {
    std::ifstream statFile("/proc/" + std::to_string(pid) + "/stat");
    std::string stat;
    if (!statFile || !std::getline(statFile, stat)) return std::nullopt;

    // The comm field (2) is wrapped in parens and may itself contain spaces
    // or parens, so parse from the last ')'.
    auto close = stat.rfind(')');
    if (close == std::string::npos || close + 2 >= stat.size()) return std::nullopt;

    std::istringstream rest(stat.substr(close + 2));
    std::string token;
    // First token after ')' is field 3 (state); we want field 22.
    for (int field = 3; field <= 22; ++field) {
        if (!(rest >> token)) return std::nullopt;
    }

    unsigned long long startTicks = 0;
    try {
        startTicks = std::stoull(token);
    } catch (...) { return std::nullopt; }

    long ticksPerSec = sysconf(_SC_CLK_TCK);
    if (ticksPerSec <= 0) return std::nullopt;

    std::ifstream upFile("/proc/uptime");
    double systemUptime = 0;
    if (!(upFile >> systemUptime)) return std::nullopt;

    double up = systemUptime - static_cast<double>(startTicks) / static_cast<double>(ticksPerSec);
    return up < 0 ? 0 : static_cast<long long>(up);
}

std::string formatDuration(long long total) {
    long long days = total / 86400;
    long long hours = (total % 86400) / 3600;
    long long mins = (total % 3600) / 60;
    long long secs = total % 60;

    std::string out;
    if (days > 0) out += std::to_string(days) + "d ";
    if (days > 0 || hours > 0) out += std::to_string(hours) + "h ";
    if (days > 0 || hours > 0 || mins > 0) out += std::to_string(mins) + "m ";
    out += std::to_string(secs) + "s";
    return out;
}

// The running instance may have been started with `-c <file>`, which this
// process can't know directly, so recover it from the instance's cmdline.
// Falls back to the default path if `-c` was not passed.
std::string runningConfigPath(pid_t pid) {
    const std::string procDir = "/proc/" + std::to_string(pid);

    std::ifstream in(procDir + "/cmdline", std::ios::binary);
    std::string raw((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());

    std::vector<std::string> args;
    std::string current;
    for (char c : raw) {
        if (c == '\0') {
            args.push_back(current);
            current.clear();
        } else {
            current += c;
        }
    }
    if (!current.empty()) args.push_back(current);

    for (size_t i = 0; i + 1 < args.size(); ++i) {
        if (args[i] == "-c") {
            std::filesystem::path p(args[i + 1]);
            if (p.is_relative()) {
                std::error_code ec;
                std::filesystem::path cwd = std::filesystem::read_symlink(procDir + "/cwd", ec);
                if (!ec) p = cwd / p;
            }
            return p.lexically_normal().string();
        }
    }
    return wisp::config::defaultPath();
}
std::string readTrimmed(const std::filesystem::path &p) {
    std::ifstream in(p);
    std::string s;
    std::getline(in, s);
    return s;
}

} // namespace

int statusInstance() {
    auto pid = findRunningWispPid();
    if (!pid) {
        std::cout << "Status:   not running\n";
        return 1;
    }

    std::cout << "Status:   running\n";
    std::cout << "PID:      " << *pid << "\n";

    if (auto up = processUptimeSeconds(*pid)) {
        std::cout << "Uptime:   " << formatDuration(*up) << "\n";
    } else {
        std::cout << "Uptime:   unknown\n";
    }

    std::cout << "Config:   " << runningConfigPath(*pid) << "\n";
    std::cout << "Version:  " << WISP_VERSION << " (" << WISP_COMMIT_HASH << ")\n";

    return 0;
}

} // namespace wisp::process