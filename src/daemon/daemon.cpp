// src/daemon/daemon.cpp

#include <csignal>
#include <string>
#include <unistd.h>

#include "logging/log.hpp"

namespace {

volatile sig_atomic_t g_stop = 0;

void handleStopSignal(int) {
    g_stop = 1;
}

void installSignalHandlers() {
    struct sigaction sa{};
    sa.sa_handler = handleStopSignal;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGTERM, &sa, nullptr);
    sigaction(SIGINT, &sa, nullptr);
}

} // namespace

int main() {
    installSignalHandlers();

    wisp::log::info("wispd", "wispd started (pid " + std::to_string(getpid()) + ")");

    // Placeholder main loop. This is where the pipewire event loop and
    // the brightness file watcher (inotify) will eventually live, each
    // reacting to events by shelling out to `qs ipc call ...`, the same
    // way wisp::ipc::exec() does today.
    while (!g_stop) { pause(); }

    wisp::log::info("wispd", "wispd stopping (received signal)");
    return 0;
}
