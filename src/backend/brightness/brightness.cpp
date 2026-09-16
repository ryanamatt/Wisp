// src/backend/brightness/brightness.cpp

#include "brightness.hpp"

#include <QProcess>
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iostream>

namespace {

constexpr const char *kBacklightRoot = "/sys/class/backlight";
constexpr const char *kLedsRoot = "/sys/class/leds";
constexpr int kDebounceMs = 80;

bool readIntFile(const QString &path, int *outValue) {
    std::ifstream file(path.toStdString());
    if (!file.is_open()) return false;
    long value = 0;
    if (!(file >> value)) return false;
    *outValue = static_cast<int>(value);
    return true;
}

// Writing here needs the same permissions brightnessctl's setuid/udev
// setup used to grant (typically membership in the "video" group plus a
// udev rule granting that group write access to the backlight/leds
// class). Without that, this fails silently from the user's
// perspective, so we at least log it once to stderr.
bool writeIntFile(const QString &path, int value) {
    std::ofstream file(path.toStdString());
    if (!file.is_open()) {
        std::cerr << "Brightness: could not open " << path.toStdString() << " for writing "
                  << "(missing permissions? this needs write access to sysfs, e.g. via udev rule)\n";
        return false;
    }
    file << value;
    return file.good();
}

} // namespace

Brightness::Brightness(QObject *parent) : QObject(parent) {
    m_brightnessWriteDebounce.setSingleShot(true);
    m_brightnessWriteDebounce.setInterval(kDebounceMs);
    connect(&m_brightnessWriteDebounce, &QTimer::timeout, this, &Brightness::writeBrightness);

    m_nightlightWriteDebounce.setSingleShot(true);
    m_nightlightWriteDebounce.setInterval(kDebounceMs);
    connect(&m_nightlightWriteDebounce, &QTimer::timeout, this, &Brightness::applyNightlight);

    m_keyboardWriteDebounce.setSingleShot(true);
    m_keyboardWriteDebounce.setInterval(kDebounceMs);
    connect(&m_keyboardWriteDebounce, &QTimer::timeout, this, &Brightness::writeKeyboardBacklight);

    connect(&m_backlightWatcher, &QFileSystemWatcher::fileChanged, this, &Brightness::onBacklightFileChanged);

    refreshBrightness();
    refreshKeyboardBacklight();
}

void Brightness::detectBacklightDevice() {
    m_hasBacklight = false;
    m_backlightPath.clear();
    m_backlightMaxRaw = 0;

    if (!std::filesystem::exists(kBacklightRoot)) return;

    for (const auto &entry : std::filesystem::directory_iterator(kBacklightRoot)) {
        QString devicePath = QString::fromStdString(entry.path().string());
        int maxRaw = 0;
        if (!readIntFile(devicePath + "/max_brightness", &maxRaw) || maxRaw <= 0) continue;

        m_backlightPath = devicePath;
        m_backlightMaxRaw = maxRaw;
        m_hasBacklight = true;
        break;
    }
}

void Brightness::refreshBrightness() {
    const bool hadBacklightBefore = m_hasBacklight;
    const int previousPercent = m_brightnessPercent;

    if (!m_hasBacklight) detectBacklightDevice();
    if (!m_hasBacklight) {
        if (hadBacklightBefore) emit brightnessChanged();
        return;
    }

    int raw = 0;
    if (!readIntFile(m_backlightPath + "/brightness", &raw)) {
        m_hasBacklight = false;
        emit brightnessChanged();
        return;
    }

    m_brightnessPercent =
        static_cast<int>(std::lround(static_cast<double>(raw) * 100.0 / static_cast<double>(m_backlightMaxRaw)));

    // (Re)watch the brightness attribute so external changes (hardware
    // keys, other tools) show up without polling. Sysfs backlight
    // devices call sysfs_notify() on this attribute when it changes, so
    // inotify picks it up.
    const QString brightnessFile = m_backlightPath + "/brightness";
    if (!m_backlightWatcher.files().contains(brightnessFile)) { m_backlightWatcher.addPath(brightnessFile); }

    // Only notify when something actually changed.
    if (!hadBacklightBefore || m_brightnessPercent != previousPercent) { emit brightnessChanged(); }
}

void Brightness::onBacklightFileChanged(const QString &path) {
    // Some kernels replace rather than truncate-and-rewrite the sysfs
    // file's watch descriptor on certain drivers. re-adding is a no-op
    // if it's already watched and cheap insurance if it isn't.
    if (!m_backlightWatcher.files().contains(path)) { m_backlightWatcher.addPath(path); }
    refreshBrightness();
}

void Brightness::setBrightness(qreal v) {
    if (!m_hasBacklight) return;

    v = std::clamp(v, 0.0, 1.0);
    m_brightnessPercent = static_cast<int>(std::lround(v * 100.0));
    m_pendingRawBrightness = static_cast<int>(std::lround(v * static_cast<double>(m_backlightMaxRaw)));
    emit brightnessChanged();

    m_brightnessWriteDebounce.start();
}

void Brightness::writeBrightness() {
    if (!m_hasBacklight) return;
    writeIntFile(m_backlightPath + "/brightness", m_pendingRawBrightness);
}

int Brightness::currentKelvin() const {
    return static_cast<int>(std::lround(kMaxKelvin - m_nightlightWarmth * (kMaxKelvin - kMinKelvin)));
}

void Brightness::toggleNightlight() {
    m_nightlightEnabled = !m_nightlightEnabled;
    emit nightlightChanged();
    applyNightlight();
}

void Brightness::setNightlightWarmth(qreal v) {
    m_nightlightWarmth = std::clamp(v, 0.0, 1.0);
    emit nightlightChanged();
    if (m_nightlightEnabled) m_nightlightWriteDebounce.start();
}

void Brightness::applyNightlight() {
    if (m_nightlightEnabled) {
        QProcess::startDetached("hyprctl", {"hyprsunset", "temperature", QString::number(currentKelvin())});
    } else {
        QProcess::startDetached("hyprctl", {"hyprsunset", "identity"});
    }
}

void Brightness::detectKeyboardBacklightDevice() {
    m_hasKeyboardBacklight = false;
    m_keyboardPath.clear();
    m_keyboardMaxRaw = 0;

    if (!std::filesystem::exists(kLedsRoot)) return;

    for (const auto &entry : std::filesystem::directory_iterator(kLedsRoot)) {
        QString name = QString::fromStdString(entry.path().filename().string());
        if (!name.contains("kbd", Qt::CaseInsensitive)) continue;

        QString devicePath = QString::fromStdString(entry.path().string());
        int maxRaw = 0;
        if (!readIntFile(devicePath + "/max_brightness", &maxRaw) || maxRaw <= 0) continue;

        m_keyboardPath = devicePath;
        m_keyboardMaxRaw = maxRaw;
        m_hasKeyboardBacklight = true;
        break;
    }
}

void Brightness::refreshKeyboardBacklight() {
    if (!m_hasKeyboardBacklight) detectKeyboardBacklightDevice();
    if (!m_hasKeyboardBacklight) {
        emit keyboardBacklightChanged();
        return;
    }

    int raw = 0;
    if (!readIntFile(m_keyboardPath + "/brightness", &raw)) {
        m_hasKeyboardBacklight = false;
        emit keyboardBacklightChanged();
        return;
    }

    m_keyboardValue = static_cast<double>(raw) / static_cast<double>(m_keyboardMaxRaw);
    emit keyboardBacklightChanged();
}

int Brightness::keyboardBacklightValue() const {
    return static_cast<int>(std::lround(m_keyboardValue * static_cast<double>(m_keyboardMaxRaw)));
}

void Brightness::updateKeyboardBacklightValue(qreal v) {
    if (!m_hasKeyboardBacklight) return;

    m_keyboardValue = std::clamp(v, 0.0, 1.0);
    emit keyboardBacklightChanged();
    m_keyboardWriteDebounce.start();
}

void Brightness::writeKeyboardBacklight() {
    if (!m_hasKeyboardBacklight) return;
    writeIntFile(m_keyboardPath + "/brightness", keyboardBacklightValue());
}
