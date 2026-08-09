// src/backend/systemMonitor/systemMonitor.cpp

#include "systemMonitor.hpp"

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <filesystem>
#include <cmath>
#include <unordered_set>

namespace {
    void populate_defaults(SystemStats* systemStats) {
        systemStats->cpuTemp = -1.0;
        systemStats->cpuUsage = -1.0;
        systemStats->memTotal = -1.0;
        systemStats->memUsed = -1.0;
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

SystemMonitor::SystemMonitor(QObject *parent) : QObject(parent) {
    populate_defaults(&systemStats);
    updateSystem();

    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &SystemMonitor::updateSystem);
    m_timer.start();
}

double SystemMonitor::cpuTemp() const { return systemStats.cpuTemp; }
double SystemMonitor::cpuUsage() const { return systemStats.cpuUsage; }

double SystemMonitor::memTotal() const { return systemStats.memTotal; }
double SystemMonitor::memUsed() const { return systemStats.memUsed; }

QVariantList SystemMonitor::partitions() const {
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

void SystemMonitor::getCpuTemp() {
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

void SystemMonitor::calculateCpuUsage() {
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

void SystemMonitor::getMemoryUsage() {
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

void SystemMonitor::getPartitions() {
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

void SystemMonitor::updateSystem() {
    getCpuTemp();
    calculateCpuUsage();
    getMemoryUsage();
    getPartitions();

    emit systemChanged();
}