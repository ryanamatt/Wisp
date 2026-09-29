// backend/time/stopwatch.hpp

#pragma once

#include <QElapsedTimer>
#include <QList>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>
#include <QVariantList>

class Stopwatch : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool idle READ idle NOTIFY stateChanged)
    Q_PROPERTY(bool running READ running NOTIFY stateChanged)
    Q_PROPERTY(bool paused READ paused NOTIFY stateChanged)

    Q_PROPERTY(qint64 elapsedMs READ elapsedMs NOTIFY elapsedChanged)
    Q_PROPERTY(QString elapsedText READ elapsedText NOTIFY elapsedChanged)

    // Newest lap first. Each entry is a map with:
    // number, lapMs, lapText, totalMs, totalText, best, worst
    // best/worst are only set once there are at least two laps.
    Q_PROPERTY(QVariantList laps READ laps NOTIFY lapsChanged)
    Q_PROPERTY(int lapCount READ lapCount NOTIFY lapsChanged)

public:
    enum State { Idle, Running, Paused };
    Q_ENUM(State)

    explicit Stopwatch(QObject *parent = nullptr);

    State state() const {
        return m_state;
    }
    bool idle() const {
        return m_state == Idle;
    }
    bool running() const {
        return m_state == Running;
    }
    bool paused() const {
        return m_state == Paused;
    }

    qint64 elapsedMs() const {
        return m_elapsedMs;
    }
    QString elapsedText() const;

    QVariantList laps() const;
    int lapCount() const {
        return static_cast<int>(m_laps.size());
    }

public slots:
    void start();  // Idle -> Running from zero, Paused -> Running
    void pause();  // Running -> Paused
    void resume(); // Paused -> Running
    void toggle(); // Idle/Paused: start/resume, Running: pause
    void lap();    // Running only: records a lap
    void reset();  // Any state -> Idle, elapsed and laps cleared

signals:
    void stateChanged();
    void elapsedChanged();
    void lapsChanged();

private slots:
    void onTick();

private:
    struct Lap {
        qint64 lapMs;
        qint64 totalMs;
    };

    qint64 currentElapsed() const;
    void setState(State s);
    void setElapsed(qint64 ms);
    static QString formatMs(qint64 ms);

    State m_state = Idle;
    qint64 m_elapsedMs = 0;
    qint64 m_baseMs = 0; // elapsed when the current run segment began
    QList<Lap> m_laps;   // chronological

    QTimer m_tick;
    QElapsedTimer m_clock; // monotonic, so tick jitter never causes drift
};
