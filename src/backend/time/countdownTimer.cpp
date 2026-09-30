// backend/time/countdownTimer.cpp

#include "countdownTimer.hpp"

#include <QProcess>
#include <QRegularExpression>
#include <algorithm>

namespace {

constexpr int kTickMs = 100;
constexpr qint64 kMaxMs = (99LL * 3600 + 59 * 60 + 59) * 1000;

} // namespace

CountdownTimer::CountdownTimer(QObject *parent) : QObject(parent) {
    m_tick.setInterval(kTickMs);
    connect(&m_tick, &QTimer::timeout, this, &CountdownTimer::onTick);
}

QString CountdownTimer::formatMs(qint64 ms) {
    // Round up so the display hits 00:00 exactly when the timer finishes.
    const qint64 totalSecs = (std::max<qint64>(ms, 0) + 999) / 1000;
    const qint64 h = totalSecs / 3600;
    const qint64 m = (totalSecs % 3600) / 60;
    const qint64 s = totalSecs % 60;

    if (h > 0) { return QStringLiteral("%1:%2:%3").arg(h).arg(m, 2, 10, QChar('0')).arg(s, 2, 10, QChar('0')); }
    return QStringLiteral("%1:%2").arg(m, 2, 10, QChar('0')).arg(s, 2, 10, QChar('0'));
}

QString CountdownTimer::totalText() const {
    return formatMs(m_totalMs);
}

QString CountdownTimer::remainingText() const {
    return formatMs(m_remainingMs);
}

qreal CountdownTimer::progress() const {
    if (m_totalMs <= 0) return 0.0;
    return static_cast<qreal>(m_remainingMs) / static_cast<qreal>(m_totalMs);
}

void CountdownTimer::setState(State s) {
    if (m_state == s) return;
    m_state = s;
    emit stateChanged();
}

void CountdownTimer::setRemaining(qint64 ms) {
    if (m_remainingMs == ms) return;
    const QString before = remainingText();
    m_remainingMs = ms;
    // Only notify when the visible text changes, or on the final tick.
    // Keeps QML from re-evaluating bindings 10 times a second.
    if (before != remainingText() || ms == 0 || ms == m_totalMs) emit remainingChanged();
}

bool CountdownTimer::setDuration(qint64 ms) {
    if (ms <= 0 || ms > kMaxMs) return false;

    m_tick.stop();
    m_totalMs = ms;
    m_remainingMs = ms;
    m_remainingAtStart = ms;
    setState(Idle);
    emit totalChanged();
    emit remainingChanged();
    return true;
}

bool CountdownTimer::setDurationText(const QString &text) {
    const QString t = text.trimmed().toLower();
    if (t.isEmpty()) return false;

    qint64 h = 0, m = 0, s = 0;
    bool ok = false;

    if (t.contains(':')) {
        // mm:ss or h:mm:ss
        const QStringList parts = t.split(':');
        if (parts.size() < 2 || parts.size() > 3) return false;

        QList<qint64> nums;
        for (const QString &p : parts) {
            const qint64 n = p.trimmed().isEmpty() ? 0 : p.trimmed().toLongLong(&ok);
            if (!p.trimmed().isEmpty() && !ok) return false;
            if (n < 0) return false;
            nums.append(n);
        }
        if (nums.size() == 3) {
            h = nums[0];
            m = nums[1];
            s = nums[2];
        } else {
            m = nums[0];
            s = nums[1];
        }
    } else {
        static const QRegularExpression unitRe(
            QStringLiteral("^(?:(\\d+)\\s*h)?\\s*(?:(\\d+)\\s*m)?\\s*(?:(\\d+)\\s*s?)?$"));
        const QRegularExpressionMatch match = unitRe.match(t);
        if (!match.hasMatch()) return false;

        const bool hasH = !match.captured(1).isEmpty();
        const bool hasM = !match.captured(2).isEmpty();
        const bool hasS = !match.captured(3).isEmpty();
        if (!hasH && !hasM && !hasS) return false;

        h = match.captured(1).toLongLong();
        m = match.captured(2).toLongLong();
        s = match.captured(3).toLongLong();

        // A bare number with no unit at all ("5") means minutes.
        if (!hasH && !hasM && hasS && !t.endsWith('s')) {
            m = s;
            s = 0;
        }
    }

    // Guard against overflow from absurd input before multiplying.
    if (h > 99 || m > 99 * 60 + 59 || s > 99 * 3600 + 59 * 60 + 59) return false;

    return setDuration(((h * 60 + m) * 60 + s) * 1000);
}

void CountdownTimer::start() {
    if (m_totalMs <= 0 || m_state == Running) return;

    if (m_state == Paused) {
        resume();
        return;
    }

    // Idle or Finished: begin from the full duration.
    m_remainingMs = m_totalMs;
    m_remainingAtStart = m_totalMs;
    m_clock.start();
    m_tick.start();
    setState(Running);
    emit remainingChanged();
}

void CountdownTimer::pause() {
    if (m_state != Running) return;

    m_tick.stop();
    setRemaining(std::max<qint64>(m_remainingAtStart - m_clock.elapsed(), 0));
    setState(Paused);
}

void CountdownTimer::resume() {
    if (m_state != Paused) return;

    m_remainingAtStart = m_remainingMs;
    m_clock.start();
    m_tick.start();
    setState(Running);
}

void CountdownTimer::toggle() {
    switch (m_state) {
        case Idle:
        case Finished: start(); break;
        case Running: pause(); break;
        case Paused: resume(); break;
    }
}

void CountdownTimer::stop() {
    m_tick.stop();
    m_remainingMs = m_totalMs;
    m_remainingAtStart = m_totalMs;
    setState(Idle);
    emit remainingChanged();
}

void CountdownTimer::onTick() {
    const qint64 remaining = std::max<qint64>(m_remainingAtStart - m_clock.elapsed(), 0);
    setRemaining(remaining);

    if (remaining > 0) return;

    m_tick.stop();
    setState(Finished);
    emit timerFinished();
}
