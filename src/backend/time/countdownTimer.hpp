// backend/time/countdownTimer.hpp

#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>

// Named CountdownTimer (not Timer) so it never collides with QtQuick's Timer
// type when both are imported in the same QML file.
class CountdownTimer : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool idle READ idle NOTIFY stateChanged)
    Q_PROPERTY(bool running READ running NOTIFY stateChanged)
    Q_PROPERTY(bool paused READ paused NOTIFY stateChanged)
    Q_PROPERTY(bool finished READ finished NOTIFY stateChanged)

    // Configured duration (what Stop resets back to).
    Q_PROPERTY(qint64 totalMs READ totalMs NOTIFY totalChanged)
    Q_PROPERTY(QString totalText READ totalText NOTIFY totalChanged)

    // Live countdown.
    Q_PROPERTY(qint64 remainingMs READ remainingMs NOTIFY remainingChanged)
    Q_PROPERTY(QString remainingText READ remainingText NOTIFY remainingChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY remainingChanged) // 1 = full, 0 = done

public:
    enum State { Idle, Running, Paused, Finished };
    Q_ENUM(State)

    explicit CountdownTimer(QObject *parent = nullptr);

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
    bool finished() const {
        return m_state == Finished;
    }

    qint64 totalMs() const {
        return m_totalMs;
    }
    QString totalText() const;
    qint64 remainingMs() const {
        return m_remainingMs;
    }
    QString remainingText() const;
    qreal progress() const;

public slots:
    // Sets the duration and resets to Idle. Returns false (and changes nothing)
    // if the value is <= 0 or above the 99:59:59 cap.
    bool setDuration(qint64 ms);

    // Accepts "mm:ss", "h:mm:ss", "1h30m20s", "5m", "90s", or a bare number
    // (treated as minutes). Returns false if the text can't be parsed.
    bool setDurationText(const QString &text);

    void start();  // Idle/Finished -> Running from the full duration
    void pause();  // Running -> Paused
    void resume(); // Paused -> Running
    void toggle(); // Idle/Finished: start, Running: pause, Paused: resume
    void stop();   // Any state -> Idle, remaining reset to the full duration

signals:
    void stateChanged();
    void totalChanged();
    void remainingChanged();
    void timerFinished(); // emitted once when the countdown reaches zero

private slots:
    void onTick();

private:
    void setState(State s);
    void setRemaining(qint64 ms);
    static QString formatMs(qint64 ms);

    State m_state = Idle;
    qint64 m_totalMs = 0;
    qint64 m_remainingMs = 0;
    qint64 m_remainingAtStart = 0; // remaining when the current run segment began

    QTimer m_tick;
    QElapsedTimer m_clock; // monotonic, so tick jitter never causes drift
};
