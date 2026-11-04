// src/process/pidfile.hpp

#pragma once

#include <filesystem>
#include <optional>
#include <string>
#include <sys/types.h>

// Helpers for locating, writing, and cleaning up wisp's runtime pid
// file, plus discovering an already-running wisp instance (via the
// pid file, falling back to a /proc scan if it's missing or stale).
namespace wisp::process {

struct VersionInfo {
    std::string version;
    std::string commit;
};

std::filesystem::path runtimeDir();
std::filesystem::path pidFilePath();
std::filesystem::path versionFilePath();

void writePidFile(pid_t pid);
void removePidFileIfOwnedBySelf();

std::optional<pid_t> findRunningWispPid();
std::optional<VersionInfo> readVersionFile(pid_t pid);

} // namespace wisp::process
