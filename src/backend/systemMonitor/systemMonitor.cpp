// src/backend/systemMonitor/systemMonitor.cpp

#include "systemMonitor.hpp"

#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>
#include <cmath>

namespace {
    void populate_defaults(SystemStats* systemStats) {
        systemStats->cpuTemp = -1.0;
        systemStats->cpuUsage = -1.0;
    }

    double roundToTenth(double value) {
        return std::round(value * 10.0) / 10.0;
    }
} // namespace

SystemMonitor::SystemMonitor(QObject *parent) : QObject(parent) {
    populate_defaults(&systemStats);
    updateSystem();

    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &SystemMonitor::updateSystem);
    m_timer.start();
}

double SystemMonitor::cpuTemp() const {
    return systemStats.cpuTemp;
}

double SystemMonitor::cpuUsage() const {
    return systemStats.cpuUsage;
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
                break; // Stop searching once found
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

void SystemMonitor::updateSystem() {
    getCpuTemp();

    calculateCpuUsage();

    emit systemChanged();
}