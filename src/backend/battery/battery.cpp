// src/backend/battery/battery.cpp

#include "battery.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <algorithm>

#include "env.hpp"

namespace {

constexpr const char *kSystemIcon = "laptop";
constexpr const char *kRazerIcon = "mouse";
constexpr const char *kHeadsetIcon = "headphones";
constexpr const char *kBluetoothIcon = "bluetooth";

constexpr const char *kLaptopName = "Laptop Battery";

constexpr const char *kSystemScript = "for b in /sys/class/power_supply/BAT*; do "
                                      "if [ -f $b/capacity ]; then "
                                      "echo $(cat $b/capacity 2>/dev/null),$(cat $b/status 2>/dev/null); "
                                      "break; fi; done";

constexpr const char *kRazerScript = "razer-cli -l 2>/dev/null";

constexpr const char *kHeadsetScript = "headsetcontrol -o json 2>/dev/null";

constexpr const char *kBluetoothScript =
    "for mac in $(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); do "
    "info=$(bluetoothctl info \"$mac\" 2>/dev/null); "
    "name=$(echo \"$info\" | grep 'Alias:' | head -n1 | cut -d' ' -f2-); "
    "batt=$(echo \"$info\" | grep 'Battery Percentage' | grep -oE '\\([0-9]+\\)' | tr -d '()'); "
    "if [ -n \"$batt\" ] && [ -n \"$name\" ]; then echo \"$name|$batt\"; fi; "
    "done";

constexpr const char *kProfileGetScript = "powerprofilesctl get 2>/dev/null";
constexpr const char *kProfileListScript = "powerprofilesctl list 2>/dev/null";

constexpr const char *kPowerSaver = "power-saver";

const QStringList &knownProfiles() {
    static const QStringList profiles = {"power-saver", "balanced", "performance"};
    return profiles;
}

} // namespace

Battery::Battery(QObject *parent) : QObject(parent) {
    // Same defaults as Config.qml: WISP_BATTERY_WARN_PERC falls back to 30 when unset or invalid.
    const int envWarn = qEnvironmentVariableIntValue(wisp::env::kBatteryWarnPerc);
    m_warnPercent = envWarn > 0 ? envWarn : kDefaultWarnPercent;

    const QString envAuto = qEnvironmentVariable(wisp::env::kBatteryAutoPowerSaver);
    m_autoPowerSaver = envAuto == "true" || envAuto == "1";

    connect(&m_systemProbe, &QProcess::finished, this, &Battery::onSystemFinished);
    connect(&m_razerProbe, &QProcess::finished, this, &Battery::onRazerFinished);
    connect(&m_headsetProbe, &QProcess::finished, this, &Battery::onHeadsetFinished);
    connect(&m_bluetoothProbe, &QProcess::finished, this, &Battery::onBluetoothFinished);
    connect(&m_profileGetProbe, &QProcess::finished, this, &Battery::onProfileGetFinished);
    connect(&m_profileListProbe, &QProcess::finished, this, &Battery::onProfileListFinished);

    // finished() isn't emitted when bash itself can't start, so treat that as "no devices".
    connect(&m_systemProbe, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) onSystemFinished();
    });
    connect(&m_razerProbe, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) onRazerFinished();
    });
    connect(&m_headsetProbe, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) onHeadsetFinished();
    });
    connect(&m_bluetoothProbe, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) onBluetoothFinished();
    });

    // Battery percentages don't change fast, so a slow poll is enough to stay current while the popup is closed.
    m_pollTimer.setInterval(kPollMs);
    connect(&m_pollTimer, &QTimer::timeout, this, &Battery::refreshAll);
    m_pollTimer.start();

    refreshAll();
}

void Battery::setWarnPercent(int percent) {
    if (percent == m_warnPercent) return;
    m_warnPercent = percent;
    emit warnPercentChanged();
    rebuild();
}

void Battery::setAutoPowerSaver(bool enabled) {
    if (enabled == m_autoPowerSaver) return;
    m_autoPowerSaver = enabled;
    emit autoPowerSaverChanged();
    checkAutoSwitch();
}

void Battery::refreshAll() {
    startProbe(&m_systemProbe, kSystemScript);
    startProbe(&m_razerProbe, kRazerScript);
    startProbe(&m_headsetProbe, kHeadsetScript);
    startProbe(&m_bluetoothProbe, kBluetoothScript);

    // The profile can be changed by other tools, so re-read it every refresh. The supported list is static, so
    // only keep asking until we've got one.
    startProbe(&m_profileGetProbe, kProfileGetScript);
    if (m_availableProfiles.isEmpty()) startProbe(&m_profileListProbe, kProfileListScript);
}

void Battery::startProbe(QProcess *proc, const QString &script) {
    if (proc->state() != QProcess::NotRunning) return;
    proc->start("bash", {"-c", script});
}

// ----- System battery -----

void Battery::onSystemFinished() {
    m_system.clear();

    // Output looks like "87,Charging".
    const QString line = QString::fromUtf8(m_systemProbe.readAllStandardOutput()).trimmed();
    if (!line.isEmpty()) {
        const QStringList parts = line.split(',');

        bool ok = false;
        const int pct = parts.value(0).trimmed().toInt(&ok);
        if (ok) {
            const QString status = parts.value(1).trimmed();
            m_system.push_back({QString::fromLatin1(kLaptopName), pct, kSystemIcon, status == "Charging"});
        }
    }

    rebuild();
}

// ----- Razer peripherals -----

std::vector<Battery::Device> Battery::parseRazerList(const QString &text) {
    struct Raw {
        QString name;
        int charge = -1; // -1 means "no charge line seen"
        bool charging = false;
    };

    static const QRegularExpression chargeRe(R"(charge:\s*(\d+))");
    static const QRegularExpression chargingRe(R"(charging:\s*(true|false))",
                                               QRegularExpression::CaseInsensitiveOption);

    std::vector<Raw> raws;
    int current = -1;
    bool inBattery = false;
    int batteryIndent = -1;

    const QStringList lines = text.split(QRegularExpression("\r?\n"));
    for (const QString &raw : lines) {
        const QString trimmed = raw.trimmed();
        if (trimmed.isEmpty()) continue;

        int indent = 0;
        while (indent < raw.size() && (raw[indent] == ' ' || raw[indent] == '\t')) ++indent;

        // Device headers sit at column 0, e.g. "Razer DeathAdder V2 Pro (Wireless):"
        if (indent == 0) {
            if (trimmed.startsWith("Razer") && trimmed.endsWith(':')) {
                raws.push_back({trimmed.chopped(1), -1, false});
                current = static_cast<int>(raws.size()) - 1;
            } else {
                current = -1;
            }
            inBattery = false;
            batteryIndent = -1;
            continue;
        }

        if (current < 0) continue;

        if (trimmed == "battery:") {
            inBattery = true;
            batteryIndent = indent;
            continue;
        }

        if (inBattery && indent <= batteryIndent) {
            inBattery = false;
            batteryIndent = -1;
        }

        if (inBattery) {
            const QRegularExpressionMatch chargeMatch = chargeRe.match(trimmed);
            if (chargeMatch.hasMatch()) raws[current].charge = chargeMatch.captured(1).toInt();

            const QRegularExpressionMatch chargingMatch = chargingRe.match(trimmed);
            if (chargingMatch.hasMatch()) raws[current].charging = chargingMatch.captured(1).toLower() == "true";
        }
    }

    std::vector<Device> devices;
    for (const Raw &r : raws) {
        if (r.charge < 0) continue;
        if (!(r.charge > 0 || r.charging)) continue;
        devices.push_back({r.name, r.charge, kRazerIcon, r.charging});
    }
    return devices;
}

void Battery::onRazerFinished() {
    m_razer = parseRazerList(QString::fromUtf8(m_razerProbe.readAllStandardOutput()));
    rebuild();
}

// ----- Headset (SteelSeries/Corsair/Logitech/etc via headsetcontrol) -----

void Battery::onHeadsetFinished() {
    m_headset.clear();

    const QJsonDocument doc = QJsonDocument::fromJson(m_headsetProbe.readAllStandardOutput());
    const QJsonArray devices = doc.object().value("devices").toArray();

    for (const QJsonValue &value : devices) {
        const QJsonObject dev = value.toObject();
        const QJsonValue batteryVal = dev.value("battery");
        if (!batteryVal.isObject()) continue;

        const QJsonObject battery = batteryVal.toObject();
        if (!battery.value("level").isDouble()) continue;

        const QString status = battery.value("status").toString();
        if (status == "BATTERY_UNAVAILABLE") continue;

        m_headset.push_back({
            dev.value("device").toString(),
            battery.value("level").toInt(),
            kHeadsetIcon,
            status == "BATTERY_CHARGING",
        });
    }

    rebuild();
}

// ----- Generic Bluetooth accessories -----

void Battery::onBluetoothFinished() {
    m_bluetooth.clear();

    // Each line looks like "WH-1000XM4|82".
    const QString text = QString::fromUtf8(m_bluetoothProbe.readAllStandardOutput());
    const QStringList lines = text.split('\n', Qt::SkipEmptyParts);

    for (const QString &line : lines) {
        if (line.trimmed().isEmpty()) continue;

        const qsizetype sep = line.lastIndexOf('|');
        if (sep < 0) continue;

        bool ok = false;
        const int pct = line.mid(sep + 1).trimmed().toInt(&ok);
        if (!ok) continue;

        m_bluetooth.push_back({line.left(sep), pct, kBluetoothIcon, false});
    }

    rebuild();
}

// ----- Power profiles -----

void Battery::onProfileGetFinished() {
    // A set is in flight, so this read may predate it. The set's completion triggers a fresh read.
    if (m_pendingProfileSets > 0) return;

    if (m_profileRefetch) {
        m_profileRefetch = false;
        startProbe(&m_profileGetProbe, kProfileGetScript);
        return;
    }

    const QString profile = QString::fromUtf8(m_profileGetProbe.readAllStandardOutput()).trimmed();
    if (profile != m_powerProfile) {
        m_powerProfile = profile;
        emit powerProfileChanged();
    }

    checkAutoSwitch();
}

void Battery::onProfileListFinished() {
    // Profile names sit at the start of a line, optionally marked with "*" for the active one, e.g.
    //   "* balanced:"
    //   "  power-saver:"
    // Their indented detail lines have values after the colon, so requiring end-of-line skips them.
    static const QRegularExpression re(R"(^\s*\*?\s*([a-z-]+):\s*$)", QRegularExpression::MultilineOption);

    const QString text = QString::fromUtf8(m_profileListProbe.readAllStandardOutput());

    QStringList profiles;
    auto it = re.globalMatch(text);
    while (it.hasNext()) {
        const QString name = it.next().captured(1);
        if (knownProfiles().contains(name) && !profiles.contains(name)) profiles.append(name);
    }

    if (profiles != m_availableProfiles) {
        m_availableProfiles = profiles;
        emit availableProfilesChanged();
    }
}

void Battery::setPowerProfile(const QString &profile) {
    if (!knownProfiles().contains(profile)) return;
    if (profile == m_powerProfile) return;

    // Update immediately so the UI responds; the read after the set corrects it if the set failed.
    m_powerProfile = profile;
    emit powerProfileChanged();

    auto *proc = new QProcess(this);
    ++m_pendingProfileSets;

    auto done = [this, proc]() {
        proc->deleteLater();
        if (--m_pendingProfileSets > 0) return;

        if (m_profileGetProbe.state() != QProcess::NotRunning) {
            m_profileRefetch = true; // the running read may predate the set
        } else {
            startProbe(&m_profileGetProbe, kProfileGetScript);
        }
    };

    connect(proc, &QProcess::finished, this, done);
    connect(proc, &QProcess::errorOccurred, this, [done](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) done();
    });

    proc->start("powerprofilesctl", {"set", profile});
}

void Battery::checkAutoSwitch() {
    if (!m_autoPowerSaver || m_system.empty()) {
        m_autoSwitched = false;
        return;
    }

    // Wait for the first profile read so we don't "switch" to what is already active.
    if (m_powerProfile.isEmpty()) return;

    const Device &laptop = m_system.front();
    const bool low = !laptop.charging && laptop.percent <= m_warnPercent;

    if (!low) {
        m_autoSwitched = false;
        return;
    }

    if (m_autoSwitched) return;
    m_autoSwitched = true;

    if (m_powerProfile != kPowerSaver) setPowerProfile(kPowerSaver);
}

// ----- Publishing -----

QVariantMap Battery::toMap(const Device &dev) const {
    return {
        {"name", dev.name},
        {"percent", dev.percent},
        {"icon", dev.icon},
        {"charging", dev.charging},
        {"sentLowNotif", m_notified.contains(dev.name)},
    };
}

void Battery::checkNotify(const std::vector<Device> &devices) {
    QSet<QString> present;

    for (const Device &dev : devices) {
        present.insert(dev.name);
        const bool alreadyNotified = m_notified.contains(dev.name);

        if (!dev.charging && !alreadyNotified && dev.percent <= m_warnPercent) {
            m_notified.insert(dev.name);
            QProcess::startDetached("notify-send",
                                    {"Low Battery", QString("%1 at %2%").arg(dev.name).arg(dev.percent)});
        } else if (dev.charging && alreadyNotified && dev.percent > m_warnPercent) {
            m_notified.remove(dev.name);
        }
    }

    // Forget devices that disappeared so they can warn again when they come back.
    m_notified.intersect(present);
}

void Battery::rebuild() {
    // Bluetooth devices that headsetcontrol already reported get dropped here so a headset connected over BT
    // doesn't show up twice.
    std::vector<Device> merged;
    merged.insert(merged.end(), m_system.begin(), m_system.end());
    merged.insert(merged.end(), m_razer.begin(), m_razer.end());
    merged.insert(merged.end(), m_headset.begin(), m_headset.end());

    for (const Device &bt : m_bluetooth) {
        const bool duplicate = std::any_of(m_headset.begin(), m_headset.end(), [&](const Device &hs) {
            return hs.name.compare(bt.name, Qt::CaseInsensitive) == 0;
        });
        if (!duplicate) merged.push_back(bt);
    }

    // Notify before building the maps so sentLowNotif reflects this pass.
    checkNotify(merged);

    QVariantList accessories;
    for (const Device &dev : merged) accessories.append(toMap(dev));

    const bool hasLaptop = !m_system.empty();
    const QVariantMap laptop = hasLaptop ? toMap(m_system.front()) : QVariantMap();

    if (accessories != m_accessories) {
        m_accessories = accessories;
        emit accessoriesChanged();
    }

    if (hasLaptop != m_hasLaptopBattery || laptop != m_laptopBattery) {
        m_hasLaptopBattery = hasLaptop;
        m_laptopBattery = laptop;
        emit laptopBatteryChanged();
    }

    checkAutoSwitch();
}
