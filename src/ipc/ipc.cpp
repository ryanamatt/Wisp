// src/ipc/ipc.cpp

#include "ipc/ipc.hpp"

#include <algorithm>
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

#include <logging/log.hpp>

namespace wisp::ipc {

namespace {

// Reads everything from fd until EOF, retrying on EINTR
std::string readAll(int fd) {
    std::string out;
    char buf[4096];
    for (;;) {
        ssize_t n = read(fd, buf, sizeof(buf));
        if (n > 0)
            out.append(buf, static_cast<size_t>(n));
        else if (n == 0)
            break;
        else if (errno != EINTR)
            break;
    }
    return out;
}

} // namespace

int exec(const std::string &qmlDir, const std::string &target, const std::string &action) {
    std::vector<char *> args;

    args.push_back(const_cast<char *>("qs"));
    args.push_back(const_cast<char *>("-c"));
    args.push_back(const_cast<char *>(qmlDir.c_str()));
    args.push_back(const_cast<char *>("ipc"));
    args.push_back(const_cast<char *>("call"));
    args.push_back(const_cast<char *>(target.c_str()));
    args.push_back(const_cast<char *>(action.c_str()));
    args.push_back(nullptr);

    execvp("qs", args.data());

    // Only reached if execvp itself failed (e.g. `qs` isn't on PATH).
    wisp::log::error(std::string("failed to run qs: ") + std::strerror(errno));
    wisp::log::error("is quickshell (qs) installed and on PATH?");
    return 127;
}

int listTargets(const std::string &qmlDir) {
    int fds[2];
    if (pipe(fds) == -1) {
        wisp::log::error(std::string("pipe failed: ") + std::strerror(errno));
        return 1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        wisp::log::error(std::string("fork failed: ") + std::strerror(errno));
        close(fds[0]);
        close(fds[1]);
        return 1;
    }

    if (pid == 0) {
        // Child: send stdout into the pipe, then become `qs`
        close(fds[0]);
        dup2(fds[1], STDOUT_FILENO);
        close(fds[1]);

        std::vector<char *> args;
        args.push_back(const_cast<char *>("qs"));
        args.push_back(const_cast<char *>("-c"));
        args.push_back(const_cast<char *>(qmlDir.c_str()));
        args.push_back(const_cast<char *>("ipc"));
        args.push_back(const_cast<char *>("show"));
        args.push_back(nullptr);

        execvp("qs", args.data());

        // Only reached if execvp failed.
        _exit(127);
    }

    close(fds[1]);
    const std::string output = readAll(fds[0]);
    close(fds[0]);

    int status = 0;
    while (waitpid(pid, &status, 0) == -1 && errno == EINTR) {}

    if (WIFEXITED(status) && WEXITSTATUS(status) == 127) {
        wisp::log::error("failed to run qs");
        wisp::log::error("is quickshell (qs) installed and on PATH?");
        return 127;
    }

    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        wisp::log::error("`qs ipc show` failed, is wisp running? (try `wisp run -d`)");
        return 1;
    }

    // Target lines start at col 0 as "target <name>".
    // Function Lines are indented, so they are skipped.
    constexpr const char kPrefix[] = "target ";
    constexpr size_t kPrefixLen = sizeof(kPrefix) - 1;

    std::vector<std::string> names;

    size_t pos = 0;
    while (pos < output.size()) {
        size_t end = output.find('\n', pos);
        if (end == std::string::npos) end = output.size();

        std::string line = output.substr(pos, end - pos);
        pos = end + 1;

        if (line.compare(0, kPrefixLen, kPrefix) != 0) continue;

        std::string name = line.substr(kPrefixLen);
        const auto last = name.find_last_not_of(" \t\r");
        if (last == std::string::npos) continue;
        name.erase(last + 1);

        if (name == std::string("lock")) continue;
        names.push_back(std::move(name));
    }

    std::sort(names.begin(), names.end());

    for (const auto &name : names) std::cout << name << "\n";

    return 0;
}

} // namespace wisp::ipc
