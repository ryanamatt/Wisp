// src/main.cpp

#include "bar/bar.hpp"
#include "cli/args.hpp"
#include "cli/logCommand.hpp"
#include "ipc/ipc.hpp"
#include "process/control.hpp"
#include "process/supervisor.hpp"

int main(int argc, char *argv[]) {
    wisp::cli::ParsedArgs parsed = wisp::cli::parse(argc, argv);
    if (parsed.earlyExit) { return *parsed.earlyExit; }

    if (parsed.disown && parsed.command != wisp::cli::Command::None) { wisp::process::daemonize(); }

    switch (parsed.command) {
        case wisp::cli::Command::Run:
            return wisp::bar::runBar(parsed.qmlDir, parsed.configPath, parsed.modulePath);
        case wisp::cli::Command::Kill:
            return wisp::process::killInstance();
        case wisp::cli::Command::Reload:
            return wisp::process::reloadInstance();
        case wisp::cli::Command::Log:
            return wisp::cli::runLogCommand(parsed.logCommand, parsed.logNum);
        case wisp::cli::Command::Ipc:
            return wisp::ipc::exec(parsed.qmlDir, parsed.ipcTarget, parsed.ipcAction);
        case wisp::cli::Command::None:
            break;
    }

    // If incorrect args print help message.
    wisp::cli::printUsage(argv[0]);
    return 0;
}
