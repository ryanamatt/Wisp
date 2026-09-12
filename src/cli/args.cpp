// src/cli/args.cpp

#include "cli/args.hpp"

#include <iostream>
#include <vector>

#include "config/config.hpp"
#include "version.hpp"

#ifndef WISP_DEFAULT_QML_DIR
#define WISP_DEFAULT_QML_DIR ""
#endif

namespace wisp::cli {

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

ParsedArgs parse(int argc, char *argv[]) {
    ParsedArgs parsed;
    parsed.qmlDir = WISP_DEFAULT_QML_DIR;
    parsed.configPath = wisp::config::defaultPath();

    std::vector<std::string> args(argv + 1, argv + argc);

    for (size_t i = 0; i < args.size(); ++i) {
        const std::string &arg = args[i];

        if (arg == "-h" || arg == "--help") {
            printUsage(argv[0]);
            parsed.earlyExit = 0;
            return parsed;
        }
        if (arg == "-v" || arg == "--version") {
            printVersion();
            parsed.earlyExit = 0;
            return parsed;
        }
        if (arg == "-d" || arg == "--disown") {
            parsed.disown = true;
            continue;
        }
        if (arg == "-f") {
            if (i + 1 >= args.size()) {
                std::cerr << "wisp: " << arg << " requires a directory argument\n";
                parsed.earlyExit = 1;
                return parsed;
            }
            parsed.qmlDir = args[++i];
            continue;
        }
        if (arg == "-c") {
            if (i + 1 >= args.size()) {
                std::cerr << "wisp: " << arg << " requires a file argument\n";
                parsed.earlyExit = 1;
                return parsed;
            }
            parsed.configPath = args[++i];
            continue;
        }
        if (arg == "-m") {
            if (i + 1 >= args.size()) {
                std::cerr << "wisp: " << arg << " requires a directory argument\n";
                parsed.earlyExit = 1;
                return parsed;
            }
            parsed.modulePath = args[++i];
            continue;
        }
        if (arg == "run") {
            parsed.command = Command::Run;
            continue;
        }
        if (arg == "kill") {
            parsed.command = Command::Kill;
            continue;
        }
        if (arg == "reload") {
            parsed.command = Command::Reload;
            continue;
        }
        if (arg == "log") {
            parsed.command = Command::Log;
            if (i + 1 < args.size()) {
                std::string logArg = args[++i];
                if (logArg == "head") parsed.logCommand = LogCommand::Head;
                else if (logArg == "tail") parsed.logCommand = LogCommand::Tail;
                else if (logArg == "clear") parsed.logCommand = LogCommand::Clear;
                else {
                    std::cerr << "wisp: unknown log argument '" << logArg << "'\n";
                    parsed.earlyExit = 1;
                    return parsed;
                }

                if (i + 1 < args.size()) {
                    std::string logNumArg = args[++i];
                    try {
                        parsed.logNum = std::stoi(logNumArg);
                    } catch (const std::exception &e) {
                        std::cerr << "wisp: invalid number for log count '" << logNumArg << "'\n";
                        parsed.earlyExit = 1;
                        return parsed;
                    }
                }
            }
            continue;
        }
        if (arg == "open" || arg == "close" || arg == "toggle") {
            parsed.command = Command::Ipc;
            parsed.ipcAction = arg;
            if (i + 1 >= args.size()) {
                std::cerr << "wisp: '" << arg << "' requires a target, e.g. `wisp " << arg << " themeSwitcher`\n";
                parsed.earlyExit = 1;
                return parsed;
            }
            parsed.ipcTarget = args[++i];
            continue;
        }

        std::cerr << "wisp: unrecognized argument '" << arg << "'\n\n";
        printUsage(argv[0]);
        parsed.earlyExit = 1;
        return parsed;
    }

    return parsed;
}

} // namespace wisp::cli
