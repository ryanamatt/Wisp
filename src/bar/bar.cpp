// src/bar/bar.cpp

#include "bar/bar.hpp"

#include <atomic>
#include <cerrno>
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <filesystem>
#include <poll.h>
#include <string>
#include <sys/wait.h>
#include <thread>
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

// Maps quickshell's own "  INFO: ..." style prefixes onto wisp log levels.
void emitQuickshellLine(std::string line) {
    while (!line.empty() && (line.back() == '\r' || line.back() == ' ')) line.pop_back();
    const auto start = line.find_first_not_of(' ');
    if (start == std::string::npos) return; // blank line
    line.erase(0, start);

    auto strip = [&](const char *prefix) {
        const std::string p = prefix;
        if (line.compare(0, p.size(), p) != 0) return false;
        line.erase(0, p.size());
        const auto s = line.find_first_not_of(' ');
        line.erase(0, s == std::string::npos ? line.size() : s);
        return true;
    };

    if (strip("DEBUG:"))
        wisp::log::debug("quickshell", line);
    else if (strip("WARN:"))
        wisp::log::warning("quickshell", line);
    else if (strip("ERROR:"))
        wisp::log::error("quickshell", line);
    else if (strip("INFO:"))
        wisp::log::info("quickshell", line);
    else
        wisp::log::info("quickshell", line); // e.g. qml console.log output
}

// Reads the child's combined stdout/stderr and forwards it line by line
// into the wisp log.
class OutputPump {
public:
    void start(int readFd) {
        fd_ = readFd;
        stop_ = false;

        // Block signals while creating the thread so it inherits a fully
        // blocked mask. Otherwise a SIGTERM/SIGHUP could be delivered to
        // this thread and the main thread's waitpid() would never see EINTR.
        sigset_t all, old;
        sigfillset(&all);
        pthread_sigmask(SIG_SETMASK, &all, &old);
        thread_ = std::thread([this] { run(); });
        pthread_sigmask(SIG_SETMASK, &old, nullptr);
    }

    // Call after the child has been reaped. Drains whatever is left, then
    // returns. Uses a flag instead of waiting for EOF because a process
    // quickshell spawned could still hold the pipe's write end open.
    void stopAndJoin() {
        stop_ = true;
        if (thread_.joinable()) thread_.join();
    }

private:
    void run() {
        std::string buf;
        char chunk[4096];
        for (;;) {
            pollfd p{fd_, POLLIN, 0};
            int r = poll(&p, 1, 100);
            if (r < 0) {
                if (errno == EINTR) continue;
                break;
            }
            if (r == 0) {
                if (stop_) break; // nothing pending and the child is gone
                continue;
            }
            ssize_t n = read(fd_, chunk, sizeof chunk);
            if (n < 0) {
                if (errno == EINTR) continue;
                break;
            }
            if (n == 0) break; // EOF
            buf.append(chunk, static_cast<size_t>(n));

            size_t pos;
            while ((pos = buf.find('\n')) != std::string::npos) {
                emitQuickshellLine(buf.substr(0, pos));
                buf.erase(0, pos + 1);
            }
        }
        if (!buf.empty()) emitQuickshellLine(buf);
        close(fd_);
    }

    int fd_ = -1;
    std::atomic<bool> stop_{false};
    std::thread thread_;
};

// Forks and execs quickshell for the given qmlDir. Returns the child's
// pid in the parent, and never returns in the child (it either execs
// or _exit(127)s on failure). Returns -1 if fork() itself failed.
pid_t spawnQuickshell(const std::string &qmlDir, OutputPump &pump) {
    int fds[2];
    if (pipe2(fds, O_CLOEXEC) != 0) {
        wisp::log::error(std::string("pipe failed: ") + std::strerror(errno));
        return -1;
    }

    // Log before forking. The child must not touch the logger's mutex.
    wisp::log::debug("exec: quickshell -c " + qmlDir);

    pid_t pid = fork();
    if (pid < 0) {
        wisp::log::error(std::string("fork failed: ") + std::strerror(errno));
        close(fds[0]);
        close(fds[1]);
        return -1;
    }

    if (pid == 0) {
        // Child: become quickshell.
        // Child: send stdout and stderr into the pipe. dup2 clears
        // O_CLOEXEC on the new descriptors, the originals close on exec.
        dup2(fds[1], STDOUT_FILENO);
        dup2(fds[1], STDERR_FILENO);

        setenv("QS_NO_RELOAD_POPUP", "1", 1);
        setenv("QT_MESSAGE_PATTERN", "%{category}: %{message} (%{file}:%{line} %{function})", 1);
        setenv("QT_LOGGING_RULES", "qt.qpa.wayland.textinput.warning=false", 1);

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

    close(fds[1]);
    pump.start(fds[0]);
    return pid;
}

// Waits for `pid` to exit, retrying if a signal intterupts the wait.
void reapChild(pid_t pid) {
    int status = 0;
    while (waitpid(pid, &status, 0) == -1 && errno == EINTR) {}
}

} // namespace

// Runs the bar by launching quickshell as a supervised child process.
// The wisp process itself stays alive (and named "wisp") for the
// lifetime of the bar, which is what lets `pgrep wisp`, `wisp kill`,
// and `wisp reload` find and control it.
int runBar(const std::string &qmlDir, const std::string &configPath, const std::string &modulePath,
           const std::string &colorsPath) {
    wisp::log::debug("runBar: qmlDir=" + qmlDir + " configPath=" + configPath +
                         " modulePath=" + (modulePath.empty() ? "<none>" : modulePath),
                     " colorsPath=" + (colorsPath.empty() ? "<none>" : colorsPath));

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

    if (!colorsPath.empty()) {
        setenv(wisp::env::kColorsPath, colorsPath.c_str(), 1);
        wisp::log::info("using colors file " + colorsPath);
    }

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

    OutputPump pump;
    pid_t child = spawnQuickshell(qmlDir, pump);
    if (child < 0) {
        wisp::log::error("failed to start the bar");
        wisp::process::removePidFileIfOwnedBySelf();
        return 1;
    }

    wisp::log::info("bar started (quickshell pid " + std::to_string(child) + ")");

    int exitCode = 0;
    for (;;) {
        // Check flags before blocking so a signla that landed while busy (for ex mid-reload)
        // is not lost
        if (wisp::process::gotTermSignal()) {
            wisp::log::info("stop signal received, shutting down");
            kill(child, SIGTERM);
            reapChild(child);
            break;
        }
        if (wisp::process::gotReloadSignal()) {
            wisp::process::clearReloadSignal();
            wisp::log::info("reload requested, restarting quickshell");

            wisp::config::load(configPath);
            wisp::log::info("reloaded config from " + configPath);

            kill(child, SIGTERM);
            reapChild(child);
            pump.stopAndJoin();
            child = spawnQuickshell(qmlDir, pump);
            if (child < 0) {
                wisp::log::error("failed to respawn quickshell during reload");
                exitCode = 1;
                break;
            }
            wisp::log::info("quickshell restarted (pid " + std::to_string(child) + ")");
            continue;
        }

        int status = 0;
        pid_t waited = waitpid(child, &status, 0);
        if (waited == -1) {
            if (errno == EINTR) continue;
            break;
        }
        pump.stopAndJoin();

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
        break;
    }

    wisp::process::removePidFileIfOwnedBySelf();
    wisp::log::info("bar stopped");
    return exitCode;
}

} // namespace wisp::bar
