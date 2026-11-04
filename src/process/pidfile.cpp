// src/process/pidfile.cpp

#include "process/pidfile.hpp"

#include <cctype>
#include <cstdlib>
#include <dirent.h>
#include <fstream>
#include <signal.h>
#include <unistd.h>

#include "logging/log.hpp"
#include "version.hpp"

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
    const pid_t parent = getppid();
    std::optional<pid_t> found;

    while (dirent *entry = readdir(proc)) {
        const std::string name = entry->d_name;
        if (name.empty() || !std::isdigit(static_cast<unsigned char>(name[0]))) continue;

        pid_t candidate = std::atoi(name.c_str());
        if (candidate == self) continue;
        // Also skip the parent: with `-d` it is the pre-fork copy of this process,
        // which may still be exiting or waitng
        if (candidate == self || candidate == parent) continue;

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

std::filesystem::path versionFilePath() {
    return runtimeDir() / "wisp.version";
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

    std::ofstream ver(versionFilePath(), std::ios::trunc);
    if (ver) {
        ver << pid << "\n" << WISP_VERSION << "\n" << WISP_COMMIT_HASH << "\n";
    } else {
        wisp::log::warning("could not write version file at " + versionFilePath().string());
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

        std::error_code verEc;
        std::filesystem::remove(versionFilePath(), verEc);
        if (verEc) {
            wisp::log::warning("could not remove version file " + versionFilePath().string() + ": " + verEc.message());
        } else {
            wisp::log::debug("removed version file " + versionFilePath().string());
        }

    }
}

std::optional<pid_t> findRunningWispPid() {
    std::ifstream in(pidFilePath());
    pid_t recorded = -1;
    if (in && (in >> recorded)) {
        // kill(pid, 0) just checks whether the pid exists/is signalable.
        if (kill(recorded, 0) == 0 && isProcessNamedWisp(recorded)) { return recorded; }
        wisp::log::debug("pid file " + pidFilePath().string() + " has stale pid " + std::to_string(recorded) +
                         ", falling back to /proc scan");
    }
    auto found = scanProcForWisp();
    if (found) { wisp::log::debug("found running wisp instance via /proc scan (pid " + std::to_string(*found) + ")"); }
    return found;
}

std::optional<VersionInfo> readVersionFile(pid_t pid) {
    std::ifstream in(versionFilePath());
    pid_t recorded = -1;
    VersionInfo info;
    if (!(in >> recorded) || recorded != pid) return std::nullopt;
    in >> std::ws;
    if (!std::getline(in, info.version) || info.version.empty()) return std::nullopt;
    std::getline(in, info.commit);
    return info;
}

} // namespace wisp::process
