// src/process/pidfile.cpp

#include "process/pidfile.hpp"

#include <cctype>
#include <csignal>
#include <cstdlib>
#include <dirent.h>
#include <fstream>
#include <string>
#include <unistd.h>

#include "logging/log.hpp"

namespace wisp::process {

namespace {

// Reads /proc/<pid>/comm and checks whether it's "wisp". This guards
// against a stale pidfile whose pid has since been recycled by an
// unrelated process.
bool isProcessNamedWisp(pid_t pid) {
    std::ifstream comm("/proc/" + std::to_string(pid) + "/comm");
    if (!comm) return false;
    std::string name;
    std::getline(comm, name);
    return name == "wisp";
}

// Falls back to scanning /proc for any process named "wisp", 
// in case the pidfile is missing or stale.
std::optional<pid_t> scanProcForWisp() {
    DIR *proc = opendir("/proc");
    if (!proc) return std::nullopt;

    const pid_t self = getpid();
    std::optional<pid_t> found;

    while (dirent *entry = readdir(proc)) {
        const std::string name = entry->d_name;
        if (name.empty() || !std::isdigit(static_cast<unsigned char>(name[0]))) continue;

        pid_t candidate = std::atoi(name.c_str());
        if (candidate == self) continue;
        if (isProcessNamedWisp(candidate)) {
            found = candidate;
            break;
        }
    }

    closedir(proc);
    return found;
}

} // namespace

std::filesystem::path runtimeDir() {
    if (const char *xdgRuntime = std::getenv("XDG_RUNTIME_DIR"); xdgRuntime && *xdgRuntime) {
        return std::filesystem::path(xdgRuntime) / "wisp";
    }
    return std::filesystem::temp_directory_path() / "wisp";
}

std::filesystem::path pidFilePath() {
    return runtimeDir() / "wisp.pid";
}

void writePidFile(pid_t pid) {
    std::error_code ec;
    std::filesystem::create_directories(runtimeDir(), ec);
    std::ofstream out(pidFilePath(), std::ios::trunc);
    if (out) {
        out << pid << "\n";
        wisp::log::debug("wrote pid file " + pidFilePath().string() + " (pid " + std::to_string(pid) + ")");
    } else {
        wisp::log::warning("could not write pid file at " + pidFilePath().string());
    }
}

void removePidFileIfOwnedBySelf() {
    std::ifstream in(pidFilePath());
    pid_t recorded = -1;
    if (in && (in >> recorded) && recorded == getpid()) {
        std::error_code ec;
        std::filesystem::remove(pidFilePath(), ec);
        if (ec) {
            wisp::log::warning("could not remove pid file " + pidFilePath().string() + ": " + ec.message());
        } else {
            wisp::log::debug("removed pid file " + pidFilePath().string());
        }
    }
}

std::optional<pid_t> findRunningWispPid() {
    std::ifstream in(pidFilePath());
    pid_t recorded = -1;
    if (in && (in >> recorded)) {
        // kill(pid, 0) just checks whether the pid exists/is signalable.
        if (kill(recorded, 0) == 0 && isProcessNamedWisp(recorded)) {
            return recorded;
        }
        wisp::log::debug(
            "pid file " + pidFilePath().string() + " has stale pid " + std::to_string(recorded) +
            ", falling back to /proc scan");
    }
    auto found = scanProcForWisp();
    if (found) {
        wisp::log::debug("found running wisp instance via /proc scan (pid " + std::to_string(*found) + ")");
    }
    return found;
}

}
