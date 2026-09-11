// src/process/control.cpp

#include "process/control.hpp"

#include <cerrno>
#include <csignal>
#include <cstring>
#include <iostream>

#include "process/pidfile.hpp"

namespace wisp::process {

int killInstance() {
    auto pid = wisp::process::findRunningWispPid();
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

int reloadInstance() {
    auto pid = wisp::process::findRunningWispPid();
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

} // namespace wisp::process