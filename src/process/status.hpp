// src/process/status.hpp

#pragma once

// User-facing `wisp status` command: reports whether a wisp instance
// is running and, if so, details about it.
namespace wisp::process {

// Returns 0 if an instance is running, 1 if not (handy for scripts).
int statusInstance();

} // namespace wisp::process
