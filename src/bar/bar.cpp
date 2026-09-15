// src/bar/bar.cpp

#include "bar/bar.hpp"

#include <cerrno>
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <optional>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

#include "config/config.hpp"
#include "env.hpp"
#include "logging/log.hpp"
#include "process/pidfile.hpp"
#include "process/supervisor.hpp"

#ifndef WISP_QML_IMPORT_PATH
#define WISP_QML_IMPORT_PATH ""
#endif

#ifndef WISP_SHARE_DIR
#define WISP_SHARE_DIR ""
#endif

namespace wisp::bar {

namespace {

// Forks and execs quickshell for the given qmlDir. Returns the child's
// pid in the parent, and never returns in the child (it either execs
// or _exit(127)s on failure). Returns -1 if fork() itself failed.
pid_t spawnQuickshell(const std::string &qmlDir) {
    pid_t pid = fork();
    if (pid < 0) {
        wisp::log::error(std::string("fork failed: ") + std::strerror(errno));
        return -1;
    }

    setenv("QS_NO_RELOAD_POPUP", "1", 1);

    if (pid == 0) {
        // Child: become quickshell.
        std::vector<char *> args;
        args.push_back(const_cast<char *>("quickshell"));
        args.push_back(const_cast<char *>("-c"));
        args.push_back(const_cast<char *>(qmlDir.c_str()));
        args.push_back(nullptr);

        wisp::log::debug("exec: quickshell -c " + qmlDir);

        execvp("quickshell", args.data());

        // Only reached if execvp itself failed.
        wisp::log::error(std::string("failed to launch quickshell: ") + std::strerror(errno));
        wisp::log::error("is quickshell installed and on PATH?");
        _exit(127);
    }

    return pid;
}

// Looks for a binary named `name` in the same directory as the
// currently running wisp executable. This is how `./build/wisp` finds
// `./build/wispd` during development without needing it on PATH, and
// it keeps working unchanged once both are installed side by side.
// Returns nullopt if /proc/self/exe can't be resolved or no such sibling
// exists, in which case the caller should fall back to a plain PATH lookup.
std::optional<std::filesystem::path> siblingBinary(const std::string &name) {
    std::error_code ec;
    std::filesystem::path exePath = std::filesystem::read_symlink("/proc/self/exe", ec);
    if (ec) return std::nullopt;

    std::filesystem::path candidate = exePath.parent_path() / name;
    if (!std::filesystem::exists(candidate, ec) || ec) return std::nullopt;

    return candidate;
}

// Forks and execs the wispd daemon. Returns the child's pid in the
// parent, and never returns in the child (it either execs or
// _exit(127)s on failure). Returns -1 if fork() itself failed.
pid_t spawnWispd() {
    pid_t pid = fork();
    if (pid < 0) {
        wisp::log::error(std::string("fork failed: ") + std::strerror(errno));
        return -1;
    }

    if (pid == 0) {
        // Child: become wispd.
        std::string wispdPath = "wispd";
        if (auto sibling = siblingBinary("wispd")) {
            wispdPath = sibling->string();
            wisp::log::debug("found wispd next to the running wisp binary: " + wispdPath);
        }

        std::vector<char *> args;
        args.push_back(const_cast<char *>(wispdPath.c_str()));
        args.push_back(nullptr);

        wisp::log::debug("exec: " + wispdPath);

        execvp(wispdPath.c_str(), args.data());

        // Only reached if execvp itself failed.
        wisp::log::error(std::string("failed to launch wispd: ") + std::strerror(errno));
        wisp::log::error("is wispd built alongside wisp, or installed and on PATH?");
        _exit(127);
    }

    return pid;
}

} // namespace

// Runs the bar by launching quickshell as a supervised child process.
// The wisp process itself stays alive (and named "wisp") for the
// lifetime of the bar, which is what lets `pgrep wisp`, `wisp kill`,
// and `wisp reload` find and control it.
int runBar(const std::string &qmlDir, const std::string &configPath, const std::string &modulePath) {
    wisp::log::debug("runBar: qmlDir=" + qmlDir + " configPath=" + configPath +
                     " modulePath=" + (modulePath.empty() ? "<none>" : modulePath));

    const std::filesystem::path shellQml = std::filesystem::path(qmlDir) / "shell.qml";

    if (!std::filesystem::exists(shellQml)) {
        wisp::log::error("cannot find shell.qml under " + qmlDir);
        return 1;
    }

    if (auto existing = wisp::process::findRunningWispPid()) {
        wisp::log::warning("an instance is already running (pid " + std::to_string(*existing) + ")");
        return 1;
    }

    wisp::config::load(configPath);
    wisp::log::info("loaded config from " + configPath);

    // -m lets a dev point at their build tree's QML modules before
    // installing, so it takes priority over both the installed
    // location and whatever the caller's shell already set.
    std::string importPath;
    if (!modulePath.empty()) {
        importPath += modulePath;
        importPath += ':';
        wisp::log::info("using extra QML module path " + modulePath);
    }
    importPath += WISP_QML_IMPORT_PATH;

    if (const char *existing = std::getenv("QML2_IMPORT_PATH"); existing && *existing) {
        wisp::log::warning("QML2_IMPORT_PATH is set in the environment (" + std::string(existing) +
                           "); ignoring it for the installed module path to avoid shadowing " +
                           std::string(WISP_QML_IMPORT_PATH));
    }

    wisp::log::debug("setting QML2_IMPORT_PATH=" + importPath);
    setenv("QML2_IMPORT_PATH", importPath.c_str(), 1);

    if (const char *existingShareDir = std::getenv(wisp::env::kShareDir); existingShareDir && *existingShareDir) {
        wisp::log::debug(std::string(wisp::env::kShareDir) + " already set in the environment (" + existingShareDir +
                         "); leaving it as-is");
    } else {
        wisp::log::debug(std::string("setting ") + wisp::env::kShareDir + "=" + WISP_SHARE_DIR);
    }
    setenv(wisp::env::kShareDir, WISP_SHARE_DIR, 0);

    wisp::log::info("environment ready: QML2_IMPORT_PATH=" + std::string(std::getenv("QML2_IMPORT_PATH")) + " " +
                    wisp::env::kShareDir + "=" + std::getenv(wisp::env::kShareDir));

    wisp::process::installSupervisorSignalHandlers();
    wisp::process::writePidFile(getpid());

    pid_t child = spawnQuickshell(qmlDir);
    if (child < 0) {
        wisp::log::error("failed to start the bar");
        wisp::process::removePidFileIfOwnedBySelf();
        return 1;
    }

    wisp::log::info("bar started (quickshell pid " + std::to_string(child) + ")");

    pid_t wispdPid = spawnWispd();
    if (wispdPid < 0) {
        wisp::log::warning("failed to start wispd, continuing without it");
    } else {
        wisp::log::info("wispd started (pid " + std::to_string(wispdPid) + ")");
    }

    int exitCode = 0;
    for (;;) {
        int status = 0;
        pid_t waited = waitpid(-1, &status, 0);

        if (waited == -1) {
            if (errno != EINTR) break;

            if (wisp::process::gotTermSignal()) {
                wisp::log::info("stop signal received, shutting down");
                kill(child, SIGTERM);
                waitpid(child, &status, 0);
                if (wispdPid > 0) {
                    kill(wispdPid, SIGTERM);
                    waitpid(wispdPid, &status, 0);
                }
                break;
            }
            if (wisp::process::gotReloadSignal()) {
                wisp::process::clearReloadSignal();
                wisp::log::info("reload requested, restarting quickshell");

                wisp::config::load(configPath);
                wisp::log::info("reloaded config from " + configPath);

                // wispd doesn't touch QML, so it rides through a
                // reload untouched; only quickshell gets restarted.
                kill(child, SIGTERM);
                waitpid(child, &status, 0);
                child = spawnQuickshell(qmlDir);
                if (child < 0) {
                    wisp::log::error("failed to respawn quickshell during reload");
                    exitCode = 1;
                    break;
                }
                wisp::log::info("quickshell restarted (pid " + std::to_string(child) + ")");
            }
            continue;
        }

        if (wispdPid > 0 && waited == wispdPid) {
            // wispd exiting isn't fatal to the bar (yet): log it and
            // keep supervising quickshell.
            if (WIFEXITED(status)) {
                wisp::log::warning("wispd exited with code " + std::to_string(WEXITSTATUS(status)));
            } else if (WIFSIGNALED(status)) {
                wisp::log::warning("wispd terminated by signal " + std::to_string(WTERMSIG(status)));
            }
            wispdPid = -1;
            continue;
        }

        // quickshell exited on its own (crash, `Qt.quit()`, etc.) -
        // there's nothing left to supervise, so wisp exits too.
        if (WIFEXITED(status)) {
            exitCode = WEXITSTATUS(status);
            if (exitCode == 0) {
                wisp::log::info("quickshell exited normally");
            } else {
                wisp::log::warning("quickshell exited with code " + std::to_string(exitCode));
            }
        } else if (WIFSIGNALED(status)) {
            exitCode = 128 + WTERMSIG(status);
            wisp::log::warning("quickshell terminated by signal " + std::to_string(WTERMSIG(status)));
        }

        if (wispdPid > 0) {
            kill(wispdPid, SIGTERM);
            waitpid(wispdPid, &status, 0);
        }
        break;
    }

    wisp::process::removePidFileIfOwnedBySelf();
    wisp::log::info("bar stopped");
    return exitCode;
}

} // namespace wisp::bar
