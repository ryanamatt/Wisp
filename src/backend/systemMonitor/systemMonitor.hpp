// src/backend/systemMonitor/systemMonitor.hpp

#pragma once

#include <QMetaType>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QThread>
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
    double uptimeSeconds;
    double loadAvg1;
    double loadAvg5;
    double loadAvg15;
} SystemStats;

Q_DECLARE_METATYPE(SystemStats)

// One real, physical partition discovered from /proc/mounts.
typedef struct {
    QString device;      // e.g. /dev/nvme0n1p2
    QString mountpoint;  // e.g. / or /home
    double total;        // GB
    double used;         // GB
} PartitionStats;

// Does the actual (blocking) work of polling /proc, /sys, and spawning
// nvidia-smi. Lives on a dedicated QThread so none of this can stall the
// QML/UI thread.
class SystemMonitorWorker : public QObject {
    Q_OBJECT

public:
    explicit SystemMonitorWorker();

public slots:
    // Connected to QThread::started(), so this only runs once the
    // worker thread's own event loop is live. Creates and starts the
    // QTimer here (a QTimer must be created on the thread it runs on).
    void start();
    void updateSystem();

signals:
    void statsReady(SystemStats stats, QVariantList partitions);

private:
    SystemStats systemStats;
    QTimer *m_timer = nullptr;

    void getCpuTemp();

    unsigned long long m_prevIdle = 0;
    unsigned long long m_prevTotal = 0;
    void calculateCpuUsage();

    void getMemoryUsage();

    void getUptime();

    void getLoadAverage();

    void getPartitions();
    std::vector<PartitionStats> m_partitions;
    QVariantList partitionsAsVariantList() const;

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
    Q_PROPERTY(double uptimeSeconds READ uptimeSeconds NOTIFY systemChanged)
    Q_PROPERTY(double loadAvg1 READ loadAvg1 NOTIFY systemChanged)
    Q_PROPERTY(double loadAvg5 READ loadAvg5 NOTIFY systemChanged)
    Q_PROPERTY(double loadAvg15 READ loadAvg15 NOTIFY systemChanged)
    Q_PROPERTY(QVariantList partitions READ partitions NOTIFY systemChanged)

public:
    explicit SystemMonitor(QObject *parent = nullptr);
    ~SystemMonitor() override;

    double cpuTemp() const;
    double cpuUsage() const;
    double memTotal() const;
    double memUsed() const;
    double gpuTemp() const;
    double gpuUsage() const;
    double uptimeSeconds() const;
    double loadAvg1() const;
    double loadAvg5() const;
    double loadAvg15() const;
    QVariantList partitions() const;

signals:
    void systemChanged();

private slots:
    // Runs on the main thread (queued connection from the worker).
    void onStatsReady(SystemStats stats, QVariantList partitions);

private:
    QThread m_workerThread;
    SystemStats systemStats;
    QVariantList m_partitions;
};
