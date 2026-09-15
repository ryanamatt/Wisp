// src/backend/brightness/brightness.hpp

#pragma once
 
#include <QFileSystemWatcher>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>

class Brightness : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // --- Backlight ---
    Q_PROPERTY(bool hasBacklight READ hasBacklight NOTIFY brightnessChanged)
    Q_PROPERTY(int brightnessPercent READ brightnessPercent NOTIFY brightnessChanged)
    Q_PROPERTY(qreal brightnessValue READ brightnessValue NOTIFY brightnessChanged)
 
    // ----- Night Light (hyprsunset) -----
    Q_PROPERTY(bool nightlightEnabled READ nightlightEnabled NOTIFY nightlightChanged)
    Q_PROPERTY(qreal nightlightWarmth READ nightlightWarmth NOTIFY nightlightChanged)
    Q_PROPERTY(int currentKelvin READ currentKelvin NOTIFY nightlightChanged)
    Q_PROPERTY(int minKelvin READ minKelvin CONSTANT)
    Q_PROPERTY(int maxKelvin READ maxKelvin CONSTANT)
 
    // ----- Keyboard Backlight -----
    Q_PROPERTY(bool hasKeyboardBacklight READ hasKeyboardBacklight NOTIFY keyboardBacklightChanged)
    Q_PROPERTY(qreal keyboardValue READ keyboardValue NOTIFY keyboardBacklightChanged)
    Q_PROPERTY(int keyboardBacklightValue READ keyboardBacklightValue NOTIFY keyboardBacklightChanged)
    Q_PROPERTY(int maxKeyboardBacklightValue READ maxKeyboardBacklightValue NOTIFY keyboardBacklightChanged)

public:
    explicit Brightness(QObject *parent = nullptr);

    bool hasBacklight() const { return m_hasBacklight; }
    int brightnessPercent() const { return m_brightnessPercent; }
    qreal brightnessValue() const { return m_brightnessPercent / 100.0; }
 
    bool nightlightEnabled() const { return m_nightlightEnabled; }
    qreal nightlightWarmth() const { return m_nightlightWarmth; }
    int currentKelvin() const;
    int minKelvin() const { return kMinKelvin; }
    int maxKelvin() const { return kMaxKelvin; }
 
    bool hasKeyboardBacklight() const { return m_hasKeyboardBacklight; }
    qreal keyboardValue() const { return m_keyboardValue; }
    int keyboardBacklightValue() const;
    int maxKeyboardBacklightValue() const { return m_keyboardMaxRaw; }

public slots:
    void refreshBrightness();
    // V is beteen 0..1, inclusive
    void setBrightness(qreal v);
 
    void toggleNightlight();
    void setNightlightWarmth(qreal v);
 
    void refreshKeyboardBacklight();
    void updateKeyboardBacklightValue(qreal v);
    
signals:
    void brightnessChanged();
    void nightlightChanged();
    void keyboardBacklightChanged();
 
private slots:
    void onBacklightFileChanged(const QString &path);
    void writeBrightness();
    void applyNightlight();
    void writeKeyboardBacklight();

private:
    static constexpr int kMinKelvin = 2500;
    static constexpr int kMaxKelvin = 6500;

    void detectBacklightDevice();
    void detectKeyboardBacklightDevice();

    // --- Backlight ---
    bool m_hasBacklight = false;
    QString m_backlightPath; // e.g. /sys/class/backlight/intel_backlight
    int m_backlightMaxRaw = 0;
    int m_brightnessPercent = 0;
    int m_pendingRawBrightness = 0;
    QFileSystemWatcher m_backlightWatcher;
    QTimer m_brightnessWriteDebounce;

    // --- Night Light ---
    bool m_nightlightEnabled = false;
    qreal m_nightlightWarmth = 0.5; // 0 = coolest (off-like), 1 = warmest
    QTimer m_nightlightWriteDebounce;
 
    // --- Keyboard Backlight ---
    bool m_hasKeyboardBacklight = false;
    QString m_keyboardPath; // e.g. /sys/class/leds/platform::kbd_backlight
    int m_keyboardMaxRaw = 0;
    qreal m_keyboardValue = 0.5;
    QTimer m_keyboardWriteDebounce;

};
