// src/process/supervisor.hpp

#pragma once

// Signal handling and daemonization for the wisp supervisor process.
namespace wisp::process {

void installSupervisorSignalHandlers();

bool gotTermSignal();

bool gotReloadSignal();
void clearReloadSignal();

// Forks and detaches wisp from the invoking shell/terminal, returning
// control to the caller's shell immediately. Used for the `-d`
// (disown) flag.
void daemonize();

} // namespace wisp::process
