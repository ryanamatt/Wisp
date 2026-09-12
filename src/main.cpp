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
#include "bar/bar.hpp"
#include "cli/logCommand.hpp"

#ifndef WISP_DEFAULT_QML_DIR
#define WISP_DEFAULT_QML_DIR ""
#endif

namespace {

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

    wisp::cli::LogCommand logCommand = wisp::cli::LogCommand::None;
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
                if (logArg == "head") logCommand = wisp::cli::LogCommand::Head;
                else if (logArg == "tail") logCommand = wisp::cli::LogCommand::Tail; 
                else if (logArg == "clear") logCommand = wisp::cli::LogCommand::Clear;
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
            return wisp::bar::runBar(qmlDir, configPath, modulePath);
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
