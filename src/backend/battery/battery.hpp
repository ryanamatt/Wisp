// src/backend/battery/battery.hpp

#pragma once

#include <QObject>
#include <QProcess>
#include <QQmlEngine>
#include <QSet>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <vector>

class Battery : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Every battery-reporting device: laptop, Razer peripherals, headsets, and Bluetooth accessories (with
    // Bluetooth devices already reported by headsetcontrol removed). Each entry is a map with the keys:
    //   name (string), percent (int), icon (string), charging (bool), sentLowNotif (bool)
    Q_PROPERTY(QVariantList accessories READ accessories NOTIFY accessoriesChanged)

    // ----- Laptop battery -----
    Q_PROPERTY(bool hasLaptopBattery READ hasLaptopBattery NOTIFY laptopBatteryChanged)
    // Same shape as an accessories entry. Empty map when there is no laptop battery.
    Q_PROPERTY(QVariantMap laptopBattery READ laptopBattery NOTIFY laptopBatteryChanged)

    // Percentage at or below which a "Low Battery" notification is sent.
    Q_PROPERTY(int warnPercent READ warnPercent WRITE setWarnPercent NOTIFY warnPercentChanged)

public:
    explicit Battery(QObject *parent = nullptr);

    QVariantList accessories() const {
        return m_accessories;
    }
    bool hasLaptopBattery() const {
        return m_hasLaptopBattery;
    }
    QVariantMap laptopBattery() const {
        return m_laptopBattery;
    }
    int warnPercent() const {
        return m_warnPercent;
    }

    void setWarnPercent(int percent);

public slots:
    // Kicks off every probe. Safe to call while probes are still running (those are skipped).
    void refreshAll();

signals:
    void accessoriesChanged();
    void laptopBatteryChanged();
    void warnPercentChanged();

private:
    static constexpr int kPollMs = 15000;
    static constexpr int kDefaultWarnPercent = 30;

    struct Device {
        QString name;
        int percent = 0;
        QString icon;
        bool charging = false;
    };

    // Starts `bash -c <script>` on the given process unless it is already running.
    void startProbe(QProcess *proc, const QString &script);

    void onSystemFinished();
    void onRazerFinished();
    void onHeadsetFinished();
    void onBluetoothFinished();

    static std::vector<Device> parseRazerList(const QString &text);

    // Merges all device lists, fires low-battery notifications, and publishes the QML-facing properties.
    void rebuild();
    void checkNotify(const std::vector<Device> &devices);
    QVariantMap toMap(const Device &dev) const;

    QTimer m_pollTimer;

    QProcess m_systemProbe;
    QProcess m_razerProbe;
    QProcess m_headsetProbe;
    QProcess m_bluetoothProbe;

    std::vector<Device> m_system;
    std::vector<Device> m_razer;
    std::vector<Device> m_headset;
    std::vector<Device> m_bluetooth;

    // Names of devices we've already warned about, so we only notify once per low-battery episode.
    QSet<QString> m_notified;

    QVariantList m_accessories;
    bool m_hasLaptopBattery = false;
    QVariantMap m_laptopBattery;

    int m_warnPercent = kDefaultWarnPercent;
};
