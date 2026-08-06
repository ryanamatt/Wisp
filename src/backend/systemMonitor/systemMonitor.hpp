// src/backend/systemMonitor/systemMonitor.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>

typedef struct {
    double cpuTemp;
    double cpuUsage;
} SystemStats;

class SystemMonitor : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(double cpuTemp READ cpuTemp NOTIFY systemChanged)
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY systemChanged)

public:
    explicit SystemMonitor(QObject *parent = nullptr);

    double cpuTemp() const;
    double cpuUsage() const;

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
};

