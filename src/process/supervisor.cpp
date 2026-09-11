// src/process/supervisor.cpp

#include "process/supervisor.hpp"

#include <cerrno>
#include <csignal>
#include <cstring>
#include <string>
#include <unistd.h>

#include "logging/log.hpp"

namespace wisp::process {

namespace {

    volatile sig_atomic_t g_gotTermSignal = 0;
    volatile sig_atomic_t g_gotReloadSignal = 0;

    void handleSupervisorSignal(int sig) {
        if (sig == SIGTERM || sig == SIGINT) {
            g_gotTermSignal = 1;
        } else if (sig == SIGUSR1) {
            g_gotReloadSignal = 1;
        }
    }

} // namespace

bool gotTermSignal() { return g_gotTermSignal != 0; }
 
bool gotReloadSignal() { return g_gotReloadSignal != 0; }
 
void clearReloadSignal() { g_gotReloadSignal = 0; }

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
        wisp::log::debug("disowned, parent exiting (child pid " + std::to_string(pid) + ")");
        _exit(0);
    }
    // Child: start a new session so we're detached from the controlling
    // terminal entirely, not just backgrounded within the old one.
    if (setsid() < 0) {
        wisp::log::warning(std::string("setsid failed: ") + std::strerror(errno));
    } else {
        wisp::log::debug("disowned, running detached (pid " + std::to_string(getpid()) + ")");
    }
}

} // namespace wisp::process