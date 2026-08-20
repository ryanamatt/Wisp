// src/ipc/ipc.cpp

#include "ipc/ipc.hpp"

#include <cerrno>
#include <cstring>
#include <unistd.h>
#include <vector>

#include <logging/log.hpp>

namespace wisp::ipc {

int exec(const std::string &qmlDir, const std::string &target, const std::string &action) {
    std::vector<char *> args;

    args.push_back(const_cast<char *>("qs"));
    args.push_back(const_cast<char *>("-c"));
    args.push_back(const_cast<char *>(qmlDir.c_str()));
    args.push_back(const_cast<char *>("ipc"));
    args.push_back(const_cast<char *>("call"));
    args.push_back(const_cast<char *>(target.c_str()));
    args.push_back(const_cast<char *>(action.c_str()));

    execvp("qs", args.data());

    // Only reached if execvp itself failed (e.g. `qs` isn't on PATH).
    wisp::log::error(std::string("failed to run qs: ") + std::strerror(errno));
    wisp::log::error("is quickshell (qs) installed and on PATH?");
    return 127;
}

} // namespace wisp::ipc
