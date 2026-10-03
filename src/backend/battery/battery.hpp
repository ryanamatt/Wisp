// src/backend/battery/battery.hpp

#pragma once

#include <QObject>
#include <QProcess>
#include <QQmlEngine>
#include <QSet>
#include <QString>
#include <QStringList>
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

    // ----- Power profiles (powerprofilesctl) -----
    Q_PROPERTY(bool hasPowerProfiles READ hasPowerProfiles NOTIFY powerProfileChanged)
    // "power-saver", "balanced" or "performance". Empty until the first read succeeds.
    Q_PROPERTY(QString powerProfile READ powerProfile NOTIFY powerProfileChanged)
    // Profiles this machine supports (performance is missing on some hardware). Empty if unknown.
    Q_PROPERTY(QStringList availableProfiles READ availableProfiles NOTIFY availableProfilesChanged)

    // When true, the laptop battery dropping to warnPercent switches to power-saver (once per low episode).
    Q_PROPERTY(bool autoPowerSaver READ autoPowerSaver WRITE setAutoPowerSaver NOTIFY autoPowerSaverChanged)

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

    bool hasPowerProfiles() const {
        return !m_powerProfile.isEmpty();
    }
    QString powerProfile() const {
        return m_powerProfile;
    }
    QStringList availableProfiles() const {
        return m_availableProfiles;
    }
    bool autoPowerSaver() const {
        return m_autoPowerSaver;
    }

    void setWarnPercent(int percent);
    void setAutoPowerSaver(bool enabled);

public slots:
    // Kicks off every probe. Safe to call while probes are still running (those are skipped).
    void refreshAll();

    // Accepts "power-saver", "balanced" or "performance"; anything else is ignored.
    void setPowerProfile(const QString &profile);

signals:
    void accessoriesChanged();
    void laptopBatteryChanged();
    void warnPercentChanged();
    void powerProfileChanged();
    void availableProfilesChanged();
    void autoPowerSaverChanged();

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
    void onProfileGetFinished();
    void onProfileListFinished();

    // Switches to power-saver the first time the laptop battery goes low, if enabled.
    void checkAutoSwitch();

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
    QProcess m_profileGetProbe;
    QProcess m_profileListProbe;

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

    QString m_powerProfile;
    QStringList m_availableProfiles;
    bool m_autoPowerSaver = false;

    // True once auto-switch has fired for the current low-battery episode, so a manual switch back to
    // balanced/performance isn't immediately overridden.
    bool m_autoSwitched = false;

    // `powerprofilesctl set` runs in flight. While any are pending, `get` results are stale and ignored.
    int m_pendingProfileSets = 0;
    bool m_profileRefetch = false;
};
