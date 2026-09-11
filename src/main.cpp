// src/main.cpp

#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <csignal>
#include <dirent.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <string>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

#include "version.hpp"
#include "config/config.hpp"
#include "env.hpp"
#include "ipc/ipc.hpp"
#include "logging/log.hpp"
#include "process/pidfile.hpp"
#include "process/supervisor.hpp"
#include "process/control.hpp"

#ifndef WISP_DEFAULT_QML_DIR
#define WISP_DEFAULT_QML_DIR ""
#endif

#ifndef WISP_QML_IMPORT_PATH
#define WISP_QML_IMPORT_PATH ""
#endif

#ifndef WISP_SHARE_DIR
#define WISP_SHARE_DIR ""
#endif

namespace {

enum class LogCommand { None, Head, Tail, Clear };

void printUsage(const char *argv0) {
    std::cout <<
        "Usage: " << argv0 << " [command] [options]\n"
        "\n"
        "Commands:\n"
        "  run                 Launch the bar\n"
        "  kill                Stop a running wisp instance\n"
        "  reload              Restart the quickshell process of a running wisp instance\n"
        "  log [head|tail|clear] [n] Print or manage log contents (default: tail 15 lines)\n"
        "  open <target>       Open a widget/popup, e.g. `wisp open themeSwitcher`\n"
        "  close <target>      Close a widget/popup, e.g. `wisp close calendar`\n"
        "  toggle <target>     Toggle a widget/popup, e.g. `wisp toggle themeSwitcher`\n"
        "\n"
        "Options:\n"
        "  -d                  Disown: return control to the shell immediately\n"
        "                      and keep running detached\n"
        "  -f <dir>            Directory containing shell.qml\n"
        "                      (default: " << WISP_DEFAULT_QML_DIR << ")\n"
        "  -m <dir>            Extra QML module import path, checked before\n"
        "                      the installed modules. Useful for testing an\n"
        "                      unreleased build without installing it, e.g.\n"
        "                      `-m build/qml` alongside `-f`.\n"
        "  -c <file>           Path to config.json\n"
        "                      (default: " << wisp::config::defaultPath() << ")\n"
        "  -h, --help          Show this help message\n"
        "  -v, --version       Show version information\n";
}

void printVersion() {
    std::cout << "wisp " << WISP_VERSION << "\n";
}

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

// Runs the bar by launching quickshell as a supervised child process.
// The wisp process itself stays alive (and named "wisp") for the
// lifetime of the bar, which is what lets `pgrep wisp`, `wisp kill`,
// and `wisp reload` find and control it.
int runBar(const std::string &qmlDir, const std::string &configPath, const std::string &modulePath) {
    wisp::log::debug(
        "runBar: qmlDir=" + qmlDir + " configPath=" + configPath +
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
        wisp::log::warning(
            "QML2_IMPORT_PATH is set in the environment (" + std::string(existing) +
            "); ignoring it for the installed module path to avoid shadowing " +
            std::string(WISP_QML_IMPORT_PATH));
    }

    wisp::log::debug("setting QML2_IMPORT_PATH=" + importPath);
    setenv("QML2_IMPORT_PATH", importPath.c_str(), 1);

    if (const char *existingShareDir = std::getenv(wisp::env::kShareDir); existingShareDir && *existingShareDir) {
        wisp::log::debug(
            std::string(wisp::env::kShareDir) + " already set in the environment (" +
            existingShareDir + "); leaving it as-is");
    } else {
        wisp::log::debug(std::string("setting ") + wisp::env::kShareDir + "=" + WISP_SHARE_DIR);
    }
    setenv(wisp::env::kShareDir, WISP_SHARE_DIR, 0);

    wisp::log::info(
        "environment ready: QML2_IMPORT_PATH=" + std::string(std::getenv("QML2_IMPORT_PATH")) +
        " " + wisp::env::kShareDir + "=" + std::getenv(wisp::env::kShareDir));

    wisp::process::installSupervisorSignalHandlers();
    wisp::process::writePidFile(getpid());

    pid_t child = spawnQuickshell(qmlDir);
    if (child < 0) {
        wisp::log::error("failed to start the bar");
        wisp::process::removePidFileIfOwnedBySelf();
        return 1;
    }

    wisp::log::info("bar started (quickshell pid " + std::to_string(child) + ")");

    int exitCode = 0;
    for (;;) {
        int status = 0;
        pid_t waited = waitpid(child, &status, 0);

        if (waited == -1) {
            if (errno != EINTR) break;

            if (wisp::process::gotTermSignal()) {
                wisp::log::info("stop signal received, shutting down");
                kill(child, SIGTERM);
                waitpid(child, &status, 0);
                break;
            }
            if (wisp::process::gotReloadSignal()) {
                wisp::process::clearReloadSignal();
                wisp::log::info("reload requested, restarting quickshell");

                wisp::config::load(configPath);
                wisp::log::info("reloaded config from " + configPath);

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
    while (std::getline(logFile, line)) {
        lines.push_back(line);
    }

    size_t start = 0;
    size_t end = lines.size();

    if (logCommand == LogCommand::Head) end = std::min(size_t(logNum), lines.size());
    else if (logCommand == LogCommand::Tail) {
        if (lines.size() > logNum) start = lines.size() - logNum;
    }

    for (size_t i = start; i < end; ++i) {
        const std::string &l = lines[i];
        std::cout << (colorize ? wisp::log::colorizeLine(l) : l) << "\n";
    }

    return 0;
}

} // namespace

int main(int argc, char *argv[]) {
    std::string qmlDir = WISP_DEFAULT_QML_DIR;
    std::string configPath = wisp::config::defaultPath();
    std::string modulePath;
    std::vector<std::string> args(argv + 1, argv + argc);

    enum class Command { None, Run, Kill, Reload, Log, Ipc };
    Command command = Command::None;

    bool disown = false;
    
    std::string ipcAction;
    std::string ipcTarget;

    LogCommand logCommand = LogCommand::None;
    int logNum = 15;

    for (size_t i = 0; i < args.size(); ++i) {
        const std::string &arg = args[i];

        if (arg == "-h" || arg == "--help") {
            printUsage(argv[0]);
            return 0;
        }
        if (arg == "-v" || arg == "--version") {
            printVersion();
            return 0;
        }
        if (arg == "-d" || arg == "--disown") {
            disown = true;
            continue;
        }
        if (arg == "-f") {
            if (i + 1 >= args.size()) {
                std::cerr << "wisp: " << arg << " requires a directory argument\n";
                return 1;
            }
            qmlDir = args[++i];
            continue;
        }
        if (arg == "-c") {
            if (i + 1 >= args.size()) {
                std::cerr << "wisp: " << arg << " requires a file argument\n";
                return 1;
            }
            configPath = args[++i];
            continue;
        }
        if (arg == "-m") {
            if (i + 1 >= args.size()) {
                std::cerr << "wisp: " << arg << " requires a directory argument\n";
                return 1;
            }
            modulePath = args[++i];
            continue;
        }
        if (arg == "run") {
            command = Command::Run;
            continue;
        }
        if (arg == "kill") {
            command = Command::Kill;
            continue;
        }
        if (arg == "reload") {
            command = Command::Reload;
            continue;
        }
        if (arg == "log") {
            command = Command::Log;
            if (i + 1 < args.size()) {
                std::string logArg = args[++i];
                if (logArg == "head") logCommand = LogCommand::Head;
                else if (logArg == "tail") logCommand = LogCommand::Tail; 
                else if (logArg == "clear") logCommand = LogCommand::Clear;
                else {
                    std::cerr << "wisp: unknown log argument '" << logArg << "'\n";
                    return 1;
                }
                
                if (i + 1 < args.size()) {
                    std::string logNumArg = args[++i];
                    try { logNum = std::stoi(logNumArg);
                    } catch (const std::exception & e) {
                        std::cerr << "wisp: invalid number for log count '" << logNumArg << "'\n";
                        return 1;
                    }
                } 
            }
            continue;
        }
        if (arg == "open" || arg == "close" || arg == "toggle") {
            command = Command::Ipc;
            ipcAction = arg;
            if (i + 1 >= args.size()) {
                std::cerr << "wisp: '" << arg << "' requires a target, e.g. `wisp " << arg << " themeSwitcher`\n";
                return 1;
            }
            ipcTarget = args[++i];
            continue;
        }

        std::cerr << "wisp: unrecognized argument '" << arg << "'\n\n";
        printUsage(argv[0]);
        return 1;
    }

    if (disown && command != Command::None) {
        wisp::process::daemonize();
    }

    switch (command) {
        case Command::Run:
            return runBar(qmlDir, configPath, modulePath);
        case Command::Kill:
            return wisp::process::killInstance();
        case Command::Reload:
            return wisp::process::reloadInstance();
        case Command::Log:
            return runLogCommand(logCommand, logNum);
        case Command::Ipc:
            return wisp::ipc::exec(qmlDir, ipcTarget, ipcAction);
        case Command::None:
            break;
    }

    // If incorrect args print help message.
    printUsage(argv[0]);
    return 0;
}
