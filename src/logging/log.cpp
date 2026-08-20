// src/logging/log.cpp

#include "log.hpp"

#include <chrono>
#include <cstdlib>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <mutex>
#include <sstream>

namespace wisp::log {

namespace {

// Log files past this size get rotated to wisp.log.old the next time
// the process starts, so a long-running bar doesn't grow an unbounded
// file.
constexpr std::uintmax_t kMaxLogFileBytes = 5ULL * 1024 * 1024;

std::mutex g_mutex;
std::ofstream g_file;
std::filesystem::path g_path;
bool g_writable = false;
bool g_initialized = false;

std::filesystem::path stateDir() {
    if (const char *xdgState = std::getenv("XDG_STATE_HOME"); xdgState && *xdgState) {
        return std::filesystem::path(xdgState) / "wisp";
    }
    if (const char *home = std::getenv("HOME"); home && *home) {
        return std::filesystem::path(home) / ".local" / "state" / "wisp";
    }
    return std::filesystem::temp_directory_path() / "wisp";
}

void rotateIfOversized(const std::filesystem::path &path) {
    std::error_code ec;
    if (!std::filesystem::exists(path, ec)) return;

    auto size = std::filesystem::file_size(path, ec);
    if (ec || size < kMaxLogFileBytes) return;

    std::filesystem::path oldPath = path;
    oldPath += ".old";
    std::filesystem::rename(path, oldPath, ec);
}

// Caller must hold g_mutex.
void ensureInitialized() {
    if (g_initialized) return;
    g_initialized = true;

    g_path = stateDir() / "wisp.log";

    std::error_code ec;
    std::filesystem::create_directories(g_path.parent_path(), ec);
    if (ec) {
        std::cerr << "wisp: could not create log directory "
                   << g_path.parent_path() << ": " << ec.message() << "\n";
    }

    rotateIfOversized(g_path);

    g_file.open(g_path, std::ios::app);
    g_writable = g_file.is_open();

    if (!g_writable) {
        std::cerr << "wisp: could not open log file " << g_path
                   << ", logging to terminal only\n";
    }
}

std::string timestamp() {
    using namespace std::chrono;
    const auto now = system_clock::now();
    const auto ms = duration_cast<milliseconds>(now.time_since_epoch()) % 1000;
    const std::time_t t = system_clock::to_time_t(now);

    std::tm tm{};
    localtime_r(&t, &tm);

    std::ostringstream ss;
    ss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
    ss << '.' << std::setw(3) << std::setfill('0') << ms.count();
    return ss.str();
}

std::string levelLabel(Level level) {
    switch (level) {
        case Level::Debug:   return "DEBUG";
        case Level::Info:    return "INFO ";
        case Level::Warning: return "WARN ";
        case Level::Error:   return "ERROR";
    }
    return "?????";
}

const char *levelColor(Level level) {
    switch (level) {
        case Level::Debug:   return "\033[2m";     // dim
        case Level::Info:    return "\033[36m";    // cyan
        case Level::Warning: return "\033[33m";     // yellow
        case Level::Error:   return "\033[1;31m";   // bold red
    }
    return "";
}

void write(Level level, const std::string &category, const std::string &message) {
    std::lock_guard<std::mutex> lock(g_mutex);
    ensureInitialized();

    const std::string tag = category.empty() ? "wisp" : category;
    const std::string plainLine =
        "[" + timestamp() + "] [" + levelLabel(level) + "] [" + tag + "] " + message;

    if (g_writable) {
        g_file << plainLine << "\n";
        g_file.flush();
    }

    const char *color = levelColor(level);
    const char *reset = "\033[0m";
    const bool toStderr = (level == Level::Warning || level == Level::Error);
    std::ostream &out = toStderr ? std::cerr : std::cout;
    out << color << plainLine << reset << "\n";
}

} // namespace

void debug(const std::string &message) { write(Level::Debug, "", message); }
void debug(const std::string &category, const std::string &message) { write(Level::Debug, category, message); }

void info(const std::string &message) { write(Level::Info, "", message); }
void info(const std::string &category, const std::string &message) { write(Level::Info, category, message); }

void warning(const std::string &message) { write(Level::Warning, "", message); }
void warning(const std::string &category, const std::string &message) { write(Level::Warning, category, message); }

void error(const std::string &message) { write(Level::Error, "", message); }
void error(const std::string &category, const std::string &message) { write(Level::Error, category, message); }

std::string filePath() {
    std::lock_guard<std::mutex> lock(g_mutex);
    ensureInitialized();
    return g_path.string();
}

} // namespace wisp::log
