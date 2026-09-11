// src/process/control.hpp

#pragma once

// User-facing commands that signal an already-running wisp instance:
// `wisp kill` and `wisp reload`.
namespace wisp::process {

int killInstance();
int reloadInstance();

} // namespace wisp::process