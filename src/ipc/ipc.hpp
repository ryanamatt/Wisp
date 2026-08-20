// src/ipc/ipc.hpp

#pragma once

#include <string>

namespace wisp::ipc {

    // Runs the Quicksehll ipc
    int exec(const std::string &qmlDir, const std::string &target, const std::string &action);

} // namespace wisp::ipc