// src/process/pidfile.hpp

#pragma once

#include <filesystem>
#include <optional>
#include <sys/types.h>

// Helpers for locating, writing, and cleaning up wisp's runtime pid
// file, plus discovering an already-running wisp instance (via the
// pid file, falling back to a /proc scan if it's missing or stale).
namespace wisp::process {

std::filesystem::path runtimeDir();
std::filesystem::path pidFilePath();

void writePidFile(pid_t pid);
void removePidFileIfOwnedBySelf();

std::optional<pid_t> findRunningWispPid();

} // namespace wisp::process
