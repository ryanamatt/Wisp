// src/backend/systemMonitor/systemMonitor.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <vector>

typedef struct {
    double cpuTemp;
    double cpuUsage;
    double memTotal;
    double memUsed;
    double gpuTemp;
    double gpuUsage;
} SystemStats;

// One real, physical partition discovered from /proc/mounts.
typedef struct {
    QString device;      // e.g. /dev/nvme0n1p2
    QString mountpoint;  // e.g. / or /home
    double total;        // GB
    double used;         // GB
} PartitionStats;

class SystemMonitor : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(double cpuTemp READ cpuTemp NOTIFY systemChanged)
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY systemChanged)
    Q_PROPERTY(double memTotal READ memTotal NOTIFY systemChanged)
    Q_PROPERTY(double memUsed READ memUsed NOTIFY systemChanged)
    Q_PROPERTY(double gpuTemp READ gpuTemp NOTIFY systemChanged)
    Q_PROPERTY(double gpuUsage READ gpuUsage NOTIFY systemChanged)
    Q_PROPERTY(QVariantList partitions READ partitions NOTIFY systemChanged)

public:
    explicit SystemMonitor(QObject *parent = nullptr);

    double cpuTemp() const;
    double cpuUsage() const;
    double memTotal() const;
    double memUsed() const;
    double gpuTemp() const;
    double gpuUsage() const;
    double diskTotal() const;
    double diskUsed() const;
    QVariantList partitions() const;

signals:
    void systemChanged();

private slots:
    void updateSystem();

private:
    QTimer m_timer;

    SystemStats systemStats;

    void getCpuTemp();

    unsigned long long m_prevIdle = 0;
    unsigned long long m_prevTotal = 0;
    void calculateCpuUsage();

    void getMemoryUsage();

    void getPartitions();
    std::vector<PartitionStats> m_partitions;

    // GPU stats: supports NVIDIA (via nvidia-smi) and other vendors
    // (AMD/Intel) via sysfs.
    enum class GpuBackend { Unknown, None, Nvidia, Amd };
    GpuBackend m_gpuBackend = GpuBackend::Unknown;
    QString m_gpuHwmonTempPath;   // cached sysfs path, non-NVIDIA only
    QString m_gpuBusyPercentPath; // cached sysfs path, non-NVIDIA only

    void getGpuStats();
    void detectGpuBackend();
    bool readNvidiaGpuStats();
    bool readAmdGpuStats();
};