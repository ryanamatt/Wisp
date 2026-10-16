// src/process/control.cpp

#include "process/control.hpp"

#include <cerrno>
#include <csignal>
#include <cstring>
#include <iostream>
#include <unistd.h>

#include "process/pidfile.hpp"

namespace wisp::process {

namespace {

// Polls until `pid` no longer exists or `timeoutMs` elapses
bool waitForExit(pid_t pid, int timeoutMs) {
    for (int waited = 0; waited < timeoutMs; waited += 50) {
        if (kill(pid, 0) != 0 && errno == ESRCH) return true;
        usleep(50 * 1000);
    }
    return false;
}

} // namespace

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

    if (!waitForExit(*pid, 5000)) {
        std::cerr << "wisp: pid " << *pid << " did not exit within 5 seconds \n";
        return 1;
    }

    std::cout << "wisp: stopped running instance (pid " << *pid << ")\n";
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
