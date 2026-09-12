// src/cli/args.hpp

#pragma once

#include <optional>
#include <string>

#include "cli/logCommand.hpp"

namespace wisp::cli {

enum class Command { None, Run, Kill, Reload, Log, Ipc };

struct ParsedArgs {
    Command command = Command::None;

    std::string qmlDir;
    std::string configPath;
    std::string modulePath;

    bool disown = false;

    std::string ipcAction;
    std::string ipcTarget;

    LogCommand logCommand = LogCommand::None;
    int logNum = 15;

    // Set when we've already printed something (help/version text, or
    // a parse error) and should exit immediately with this code,
    // without dispatching to a command.
    std::optional<int> earlyExit;
};

void printUsage(const char *argv0);
void printVersion();

ParsedArgs parse(int argc, char *argv[]);

} // namespace wisp::cli
