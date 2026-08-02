// src/main.cpp

#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <string>
#include <vector>
#include <unistd.h>

#include "config/config.hpp"

#ifndef WISP_VERSION
#define WISP_VERSION "0.0.0-dev"
#endif

#ifndef WISP_DEFAULT_QML_DIR
#define WISP_DEFAULT_QML_DIR ""
#endif

#ifndef WISP_QML_IMPORT_PATH
#define WISP_QML_IMPORT_PATH ""
#endif

namespace {

void printUsage(const char *argv0) {
    std::cout <<
        "Usage: " << argv0 << " [command] [options]\n"
        "\n"
        "Commands:\n"
        "  run                 Launch the bar\n"
        "\n"
        "Options:\n"
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

// Runs the bar by exec'ing into quickshell, replacing this process
// entirely. signals, stdio, and the exit code all pass straight
// through, same as `exec` in a shell script.
int runBar(const std::string &qmlDir, const std::string &configPath) {
    const std::filesystem::path shellQml = std::filesystem::path(qmlDir) / "shell.qml";

    if (!std::filesystem::exists(shellQml)) {
        std::cerr << "wisp: cannot find shell.qml under " << qmlDir << "\n";
        return 1;
    }

    wisp::config::load(configPath);

    // Prepend our bundled QML backend (e.g. Wisp.Time) to
    // QML2_IMPORT_PATH, keeping anything the user already has set so
    // this composes with other backend/configs.
    std::string importPath = WISP_QML_IMPORT_PATH;
    if (const char *existing = std::getenv("QML2_IMPORT_PATH"); existing && *existing) {
        importPath += ':';
        importPath += existing;
    }
    setenv("QML2_IMPORT_PATH", importPath.c_str(), 1);

    std::vector<char *> args;
    args.push_back(const_cast<char *>("quickshell"));
    args.push_back(const_cast<char *>("-c"));
    args.push_back(const_cast<char *>(qmlDir.c_str()));
    args.push_back(nullptr);

    execvp("quickshell", args.data());

    // Only reached if execvp itself failed (e.g. quickshell not on PATH).
    std::cerr << "wisp: failed to launch quickshell: " << std::strerror(errno) << "\n";
    std::cerr << "wisp: is quickshell installed and on PATH?\n";
    return 127;
}

} // namespace

int main(int argc, char *argv[]) {
    std::string qmlDir = WISP_DEFAULT_QML_DIR;
    std::string configPath = wisp::config::defaultPath();
    std::vector<std::string> args(argv + 1, argv + argc);

    bool isRunRequested = false;

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
            isRunRequested = true;
            continue;
        }

        std::cerr << "wisp: unrecognized argument '" << arg << "'\n\n";
        printUsage(argv[0]);
        return 1;
    }

    if (isRunRequested) return runBar(qmlDir, configPath);

    // If incorrect args print help message.
    printUsage(argv[0]);
    return 0;
}
