// src/main.cpp

#include <cerrno>
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

volatile sig_atomic_t g_gotTermSignal = 0;
volatile sig_atomic_t g_gotReloadSignal = 0;

void printUsage(const char *argv0) {
    std::cout <<
        "Usage: " << argv0 << " [command] [options]\n"
        "\n"
        "Commands:\n"
        "  run                 Launch the bar\n"
        "  kill                Stop a running wisp instance\n"
        "  reload              Restart the quickshell process of a running wisp instance\n"
        "  open <target>       Open a widget/popup, e.g. `wisp open themeSwitcher`\n"
        "  close <target>      Close a widget/popup, e.g. `wisp close calendar`\n"
        "  toggle <target>     Toggle a widget/popup, e.g. `wisp toggle themeSwitcher`\n"
        "\n"
        "Options:\n"
        "  -d                  Disown: return control to the shell immediately\n"
        "                      and keep running detached\n"
        "  -f <dir>            Directory containing shell.qml\n"
        "                      (default: " << WISP_DEFAULT_QML_DIR << ")\n"
        "  -c <file>           Path to config.json\n"
        "                      (default: " << wisp::config::defaultPath() << ")\n"
        "  -h, --help          Show this help message\n"
        "  -v, --version       Show version information\n";
}

void printVersion() {
    std::cout << "wisp " << WISP_VERSION << "\n";
}

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
    }
}

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

std::optional<pid_t> findRunningWispPid() {
    std::ifstream in(pidFilePath());
    pid_t recorded = -1;
    if (in && (in >> recorded)) {
        // kill(pid, 0) just checks whether the pid exists/is signalable.
        if (kill(recorded, 0) == 0 && isProcessNamedWisp(recorded)) {
            return recorded;
        }
    }
    return scanProcForWisp();
}

void handleSupervisorSignal(int sig) {
    if (sig == SIGTERM || sig == SIGINT) {
        g_gotTermSignal = 1;
    } else if (sig == SIGUSR1) {
        g_gotReloadSignal = 1;
    }
}

void installSupervisorSignalHandlers() {
    struct sigaction sa {};
    sa.sa_handler = handleSupervisorSignal;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0; // deliberately no SA_RESTART, so waitpid() wakes up
    sigaction(SIGTERM, &sa, nullptr);
    sigaction(SIGINT, &sa, nullptr);
    sigaction(SIGUSR1, &sa, nullptr);
}

// Detaches from the invoking shell
void daemonize() {
    pid_t pid = fork();
    if (pid < 0) {
        wisp::log::error(std::string("failed to disown: fork failed: ") + std::strerror(errno));
        return; // fall back to running in the foreground
    }
    if (pid > 0) {
        // Parent: nothing left to do, hand control back to the shell.
        _exit(0);
    }
    // Child: start a new session so we're detached from the controlling
    // terminal entirely, not just backgrounded within the old one.
    if (setsid() < 0) {
        wisp::log::warning(std::string("setsid failed: ") + std::strerror(errno));
    }
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

    if (pid == 0) {
        // Child: become quickshell.
        std::vector<char *> args;
        args.push_back(const_cast<char *>("quickshell"));
        args.push_back(const_cast<char *>("-c"));
        args.push_back(const_cast<char *>(qmlDir.c_str()));
        args.push_back(nullptr);

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
int runBar(const std::string &qmlDir, const std::string &configPath) {
    const std::filesystem::path shellQml = std::filesystem::path(qmlDir) / "shell.qml";

    if (!std::filesystem::exists(shellQml)) {
        wisp::log::error("cannot find shell.qml under " + qmlDir);
        return 1;
    }

    if (auto existing = findRunningWispPid()) {
        wisp::log::warning("an instance is already running (pid " + std::to_string(*existing) + ")");
        return 1;
    }

    wisp::config::load(configPath);
    wisp::log::info("loaded config from " + configPath);

    std::string importPath = WISP_QML_IMPORT_PATH;
    if (const char *existing = std::getenv("QML2_IMPORT_PATH"); existing && *existing) {
        importPath += ':';
        importPath += existing;
    }
    setenv("QML2_IMPORT_PATH", importPath.c_str(), 1);
    setenv(wisp::env::kShareDir, WISP_SHARE_DIR, 1);

    installSupervisorSignalHandlers();
    writePidFile(getpid());

    pid_t child = spawnQuickshell(qmlDir);
    if (child < 0) {
        wisp::log::error("failed to start the bar");
        removePidFileIfOwnedBySelf();
        return 1;
    }

    wisp::log::info("bar started (quickshell pid " + std::to_string(child) + ")");

    int exitCode = 0;
    for (;;) {
        int status = 0;
        pid_t waited = waitpid(child, &status, 0);

        if (waited == -1) {
            if (errno != EINTR) break;

            if (g_gotTermSignal) {
                wisp::log::info("stop signal received, shutting down");
                kill(child, SIGTERM);
                waitpid(child, &status, 0);
                break;
            }
            if (g_gotReloadSignal) {
                g_gotReloadSignal = 0;
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

    removePidFileIfOwnedBySelf();
    wisp::log::info("bar stopped");
    return exitCode;
}

int killBar() {
    auto pid = findRunningWispPid();
    if (!pid) {
        std::cerr << "wisp: no running instance found\n";
        return 1;
    }

    if (kill(*pid, SIGTERM) != 0) {
        std::cerr << "wisp: failed to signal pid " << *pid << ": " << std::strerror(errno) << "\n";
        return 1;
    }

    std::cout << "wisp: sent stop signal to running instance (pid " << *pid << ")\n";
    return 0;
}

int reloadBar() {
    auto pid = findRunningWispPid();
    if (!pid) {
        std::cerr << "wisp: no running instance found\n";
        return 1;
    }

    if (kill(*pid, SIGUSR1) != 0) {
        std::cerr << "wisp: failed to signal pid " << *pid << ": " << std::strerror(errno) << "\n";
        return 1;
    }

    std::cout << "wisp: reloading running instance (pid " << *pid << ")\n";
    return 0;
}

} // namespace

int main(int argc, char *argv[]) {
    std::string qmlDir = WISP_DEFAULT_QML_DIR;
    std::string configPath = wisp::config::defaultPath();
    std::vector<std::string> args(argv + 1, argv + argc);

    enum class Command { None, Run, Kill, Reload, Ipc };
    Command command = Command::None;
    bool disown = false;
    std::string ipcAction;
    std::string ipcTarget;

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
        daemonize();
    }

    switch (command) {
        case Command::Run:
            return runBar(qmlDir, configPath);
        case Command::Kill:
            return killBar();
        case Command::Reload:
            return reloadBar();
        case Command::Ipc:
            return wisp::ipc::exec(qmlDir, ipcTarget, ipcAction);
        case Command::None:
            break;
    }

    // If incorrect args print help message.
    printUsage(argv[0]);
    return 0;
}
