// src/backend/systemMonitor/systemMonitor.cpp

#include "systemMonitor.hpp"

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <filesystem>
#include <cmath>
#include <unordered_set>
#include <cstdio>
#include <array>
#include <memory>
#include <stdio.h>

namespace {

    struct PcloseDeleter {
        void operator()(FILE* fp) const {
            if (fp) {
                pclose(fp);
            }
        }
    };

    void populate_defaults(SystemStats* systemStats) {
        systemStats->cpuTemp = -1.0;
        systemStats->cpuUsage = -1.0;
        systemStats->memTotal = -1.0;
        systemStats->memUsed = -1.0;
        systemStats->gpuTemp = -1.0;
        systemStats->gpuUsage = -1.0;
        systemStats->uptimeSeconds = -1.0;
    }

    // Runs a shell command and returns its stdout, or empty string on failure.
    std::string runCommand(const std::string& cmd) {
        std::array<char, 256> buffer;
        std::string result;
        // Redirect stderr to /dev/null so a missing binary doesn't spam the console.
        std::string fullCmd = cmd + " 2>/dev/null";

        std::unique_ptr<FILE, PcloseDeleter> pipe(popen(fullCmd.c_str(), "r"));
        if (!pipe) return result;

        while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe.get()) != nullptr) {
            result += buffer.data();
        }
        return result;
    }

    double roundToTenth(double value) {
        return std::round(value * 10.0) / 10.0;
    }

    // Only these fstypes count as "real" partitions worth showing. Everything else
    // (tmpfs, proc, sysfs, overlay, squashfs snap mounts, cgroup, etc.) not counted.
    bool isRealFilesystem(const std::string& fstype) {
        static const std::unordered_set<std::string> realFsTypes = {
            "ext2", "ext3", "ext4", "xfs", "btrfs", "f2fs", "jfs",
            "reiserfs", "vfat", "exfat", "ntfs", "ntfs3", "zfs",
            "hfsplus", "apfs"
        };
        return realFsTypes.count(fstype) > 0;
    }

    // Some mountpoints (e.g. Docker/snap bind mounts, or duplicate entries
    // for the same subvolume) share a device+mountpoint pair. Skip repeats.
    struct MountKey {
        std::string device;
        std::string mountpoint;
        bool operator==(const MountKey& o) const {
            return device == o.device && mountpoint == o.mountpoint;
        }
    };
    struct MountKeyHash {
        size_t operator()(const MountKey& k) const {
            return std::hash<std::string>()(k.device) ^ (std::hash<std::string>()(k.mountpoint) << 1);
        }
    };

    // /proc/mounts escapes spaces etc. as octal (e.g. \040). Undo that.
    std::string unescapeMountField(const std::string& field) {
        std::string result;
        result.reserve(field.size());
        for (size_t i = 0; i < field.size(); ++i) {
            if (field[i] == '\\' && i + 3 < field.size() &&
                isdigit(field[i+1]) && isdigit(field[i+2]) && isdigit(field[i+3])) {
                int code = (field[i+1] - '0') * 64 + (field[i+2] - '0') * 8 + (field[i+3] - '0');
                result += static_cast<char>(code);
                i += 3;
            } else {
                result += field[i];
            }
        }
        return result;
    }
    
} // namespace

// SystemMonitorWorker: runs on its own QThread, does all the blocking
// work, and hands finished results back to the main thread via a
// queued signal.

SystemMonitorWorker::SystemMonitorWorker() {
    populate_defaults(&systemStats);
}

void SystemMonitorWorker::start() {
    // Populate immediately so the UI isn't stuck at defaults for the
    // first second, then keep polling on our own timer.
    updateSystem();

    m_timer = new QTimer(this);
    m_timer->setInterval(1000);
    connect(m_timer, &QTimer::timeout, this, &SystemMonitorWorker::updateSystem);
    m_timer->start();
}

void SystemMonitorWorker::getCpuTemp() {
    for (const auto & entry : std::filesystem::directory_iterator("/sys/class/thermal/")) {
        std::string zone_path = entry.path().string();
        std::string type_path = zone_path + "/type";
        std::string temp_path = zone_path + "/temp";

        // Read the type file
        std::ifstream type_file(type_path);
        if (type_file.is_open()) {
            std::string type_name;
            std::getline(type_file, type_name);
            type_file.close();

            // Check if this zone is the x86 CPU package sensor
            if (type_name == "x86_pkg_temp") {
                std::ifstream temp_file(temp_path);
                if (temp_file.is_open()) {
                    long raw_temp;
                    if (temp_file >> raw_temp) {
                        // Value is in millidegrees Celsius, convert to Celsius
                        systemStats.cpuTemp = static_cast<double>(raw_temp) / 1000.0;
                    }
                    temp_file.close();
                }
                break;
            }
        }
    }
}

void SystemMonitorWorker::calculateCpuUsage() {
    std::ifstream stat_file("/proc/stat");
    if (!stat_file.is_open()) return;

    std::string line;
    if (std::getline(stat_file, line)) {
        std::istringstream ss(line);
        std::string cpu;
        unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
        ss >> cpu >> user >> nice >> system >> idle >> iowait >> irq >> softirq >> steal;

        unsigned long long idle_time = idle + iowait;
        unsigned long long non_idle = user + nice + system + irq + softirq + steal;
        unsigned long long total_time = idle_time + non_idle;

        if (m_prevTotal != 0 && total_time > m_prevTotal) {
            unsigned long long total_delta = total_time - m_prevTotal;
            unsigned long long idle_delta = idle_time - m_prevIdle;

            double usage = static_cast<double>(total_delta - idle_delta) / static_cast<double>(total_delta) * 100.0;
            systemStats.cpuUsage = roundToTenth(usage);
        }

        m_prevTotal = total_time;
        m_prevIdle = idle_time;
    }
}

void SystemMonitorWorker::getMemoryUsage() {
    std::ifstream meminfo_file("/proc/meminfo");
    if (!meminfo_file.is_open()) return;

    std::string line;
    unsigned long long memTotalKb = 0;
    unsigned long long memFreeKb = 0;
    unsigned long long buffersKb = 0;
    unsigned long long cachedKb = 0;

    while (std::getline(meminfo_file, line)) {
        std::istringstream ss(line);
        std::string key;
        unsigned long long value;
        std::string unit;

        ss >> key >> value >> unit;

        if (key == "MemTotal:") {
            memTotalKb = value;
        } else if (key == "MemFree:") {
            memFreeKb = value;
        } else if (key == "Buffers:") {
            buffersKb = value;
        } else if (key == "Cached:") {
            cachedKb = value;
        }
    }

    if (memTotalKb > 0) {
        // Used memory calculation: Total - Free - Buffers - Cached
        unsigned long long memUsedKb = memTotalKb - memFreeKb - buffersKb - cachedKb;

        // Convert KB to GB (or use / 1024.0 for MB)
        systemStats.memTotal = roundToTenth(static_cast<double>(memTotalKb) / 1024.0 / 1024.0);
        systemStats.memUsed = roundToTenth(static_cast<double>(memUsedKb) / 1024.0 / 1024.0);
    }
}

void SystemMonitorWorker::getUptime() {
    std::ifstream uptime_file("/proc/uptime");
    if (!uptime_file.is_open()) return;

    double uptime = 0.0;
    if (uptime_file >> uptime) {
        systemStats.uptimeSeconds = uptime;
    }
}

void SystemMonitorWorker::getPartitions() {
    std::vector<PartitionStats> found;
    std::unordered_set<MountKey, MountKeyHash> seen;

    std::ifstream mounts_file("/proc/mounts");
    if (!mounts_file.is_open()) {
        std::cerr << "Error: could not open /proc/mounts\n";
        return;
    }

    std::string line;
    while (std::getline(mounts_file, line)) {
        std::istringstream ss(line);
        std::string device, mountpointRaw, fstype, options;
        int dump, pass;
        if (!(ss >> device >> mountpointRaw >> fstype >> options >> dump >> pass)) {
            continue;
        }

        if (!isRealFilesystem(fstype)) continue;

        std::string mountpoint = unescapeMountField(mountpointRaw);

        MountKey key{device, mountpoint};
        if (seen.count(key)) continue;
        seen.insert(key);

        try {
            std::filesystem::space_info inf = std::filesystem::space(mountpoint);
            if (inf.capacity == 0) continue;

            double totalGb = static_cast<double>(inf.capacity) / (1024.0 * 1024.0 * 1024.0);
            double freeGb = static_cast<double>(inf.free) / (1024.0 * 1024.0 * 1024.0);
            double usedGb = totalGb - freeGb;

            PartitionStats p;
            p.device = QString::fromStdString(device);
            p.mountpoint = QString::fromStdString(mountpoint);
            p.total = roundToTenth(totalGb);
            p.used = roundToTenth(usedGb);
            found.push_back(p);
        } catch (const std::filesystem::filesystem_error& e) {
            std::cerr << "Error reading disk space for " << mountpoint << ": " << e.what() << '\n';
        }
    }

    m_partitions = std::move(found);
}

QVariantList SystemMonitorWorker::partitionsAsVariantList() const {
    QVariantList list;
    list.reserve(static_cast<int>(m_partitions.size()));
    for (const auto& p : m_partitions) {
        QVariantMap entry;
        entry["device"] = p.device;
        entry["mountpoint"] = p.mountpoint;
        entry["total"] = p.total;
        entry["used"] = p.used;
        list.append(entry);
    }
    return list;
}

// Figures out once which GPU backend to use, then caches it (and any
// sysfs paths it needs) so we're not re-probing every second.
void SystemMonitorWorker::detectGpuBackend() {
    m_gpuBackend = GpuBackend::None;

    // Prefer NVIDIA via nvidia-smi when it's present, since it reports
    // both temp and utilization directly and needs no sysfs guessing.
    std::string nvOutput = runCommand(
        "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits");
    if (!nvOutput.empty()) {
        m_gpuBackend = GpuBackend::Nvidia;
        return;
    }

    // Fall back to scanning /sys/class/drm for a card whose PCI vendor ID
    // is AMD (0x1002), and cache the hwmon temp + gpu_busy_percent paths.
    const std::string drmRoot = "/sys/class/drm";
    if (!std::filesystem::exists(drmRoot)) return;

    for (const auto& entry : std::filesystem::directory_iterator(drmRoot)) {
        std::string name = entry.path().filename().string();
        // Only look at bare "cardN" entries, not render nodes etc.
        if (name.rfind("card", 0) != 0 || name.find('-') != std::string::npos) continue;

        std::filesystem::path devicePath = entry.path() / "device";
        std::ifstream vendorFile(devicePath / "vendor");
        std::string vendor;
        if (!vendorFile.is_open() || !(vendorFile >> vendor)) continue;

        if (vendor != "0x1002") continue; // not AMD

        std::filesystem::path busyPath = devicePath / "gpu_busy_percent";
        if (!std::filesystem::exists(busyPath)) continue;

        // hwmon dir name varies (hwmon0, hwmon1, ...), so find it.
        std::filesystem::path hwmonRoot = devicePath / "hwmon";
        if (!std::filesystem::exists(hwmonRoot)) continue;

        for (const auto& hwmonEntry : std::filesystem::directory_iterator(hwmonRoot)) {
            std::filesystem::path tempPath = hwmonEntry.path() / "temp1_input";
            if (std::filesystem::exists(tempPath)) {
                m_gpuHwmonTempPath = QString::fromStdString(tempPath.string());
                m_gpuBusyPercentPath = QString::fromStdString(busyPath.string());
                m_gpuBackend = GpuBackend::Amd;
                return;
            }
        }
    }
}

bool SystemMonitorWorker::readNvidiaGpuStats() {
    std::string output = runCommand(
        "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits");
    if (output.empty()) return false;

    std::istringstream ss(output);
    std::string tempStr, usageStr;
    if (!std::getline(ss, tempStr, ',')) return false;
    if (!std::getline(ss, usageStr)) return false;

    try {
        systemStats.gpuTemp = std::stod(tempStr);
        systemStats.gpuUsage = std::stod(usageStr);
    } catch (const std::exception&) {
        return false;
    }
    return true;
}

bool SystemMonitorWorker::readAmdGpuStats() {
    if (m_gpuHwmonTempPath.isEmpty() || m_gpuBusyPercentPath.isEmpty()) return false;

    std::ifstream tempFile(m_gpuHwmonTempPath.toStdString());
    std::ifstream busyFile(m_gpuBusyPercentPath.toStdString());
    if (!tempFile.is_open() || !busyFile.is_open()) return false;

    long rawTemp = 0;
    long busyPercent = 0;
    if (!(tempFile >> rawTemp)) return false;
    if (!(busyFile >> busyPercent)) return false;

    // temp1_input is in millidegrees Celsius.
    systemStats.gpuTemp = roundToTenth(static_cast<double>(rawTemp) / 1000.0);
    systemStats.gpuUsage = static_cast<double>(busyPercent);
    return true;
}

void SystemMonitorWorker::getGpuStats() {
    if (m_gpuBackend == GpuBackend::Unknown) {
        detectGpuBackend();
    }

    bool ok = false;
    switch (m_gpuBackend) {
        case GpuBackend::Nvidia:
            ok = readNvidiaGpuStats();
            break;
        case GpuBackend::Amd:
            ok = readAmdGpuStats();
            break;
        case GpuBackend::None:
        case GpuBackend::Unknown:
        default:
            ok = false;
            break;
    }

    if (!ok) {
        systemStats.gpuTemp = -1.0;
        systemStats.gpuUsage = -1.0;
    }
}

void SystemMonitorWorker::updateSystem() {
    getCpuTemp();
    calculateCpuUsage();
    getMemoryUsage();
    getUptime();
    getPartitions();
    getGpuStats();

    emit statsReady(systemStats, partitionsAsVariantList());
}

// SystemMonitor: lives on the main/QML thread. Owns the worker thread
// and just mirrors whatever the worker last reported.
SystemMonitor::SystemMonitor(QObject *parent) : QObject(parent) {
    populate_defaults(&systemStats);

    qRegisterMetaType<SystemStats>("SystemStats");

    auto *worker = new SystemMonitorWorker();
    worker->moveToThread(&m_workerThread);

    // Start polling once the worker thread's event loop is actually running.
    connect(&m_workerThread, &QThread::started, worker, &SystemMonitorWorker::start);

    // Queued connection: statsReady is emitted on the worker thread,
    // onStatsReady runs on this (main) thread.
    connect(worker, &SystemMonitorWorker::statsReady,
            this, &SystemMonitor::onStatsReady, Qt::QueuedConnection);

    // Clean up the worker once the thread is done.
    connect(&m_workerThread, &QThread::finished, worker, &QObject::deleteLater);

    m_workerThread.start();
}

SystemMonitor::~SystemMonitor() {
    m_workerThread.quit();
    m_workerThread.wait();
}

double SystemMonitor::cpuTemp() const { return systemStats.cpuTemp; }
double SystemMonitor::cpuUsage() const { return systemStats.cpuUsage; }

double SystemMonitor::memTotal() const { return systemStats.memTotal; }
double SystemMonitor::memUsed() const { return systemStats.memUsed; }

double SystemMonitor::gpuTemp() const { return systemStats.gpuTemp; }
double SystemMonitor::gpuUsage() const { return systemStats.gpuUsage; }

double SystemMonitor::uptimeSeconds() const { return systemStats.uptimeSeconds; }

QVariantList SystemMonitor::partitions() const { return m_partitions; }

void SystemMonitor::onStatsReady(SystemStats stats, QVariantList partitions) {
    systemStats = stats;
    m_partitions = std::move(partitions);
    emit systemChanged();
}
