// src/cli/logCommand.hpp

#pragma once

// The `wisp log [head|tail|clear] [n]` command: prints or manages
// the contents of wisp's log file.
namespace wisp::cli {

enum class LogCommand { None, Head, Tail, Clear };

int runLogCommand(LogCommand logCommand, int logNum);

} // namespace wisp::cli