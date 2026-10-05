// backend/time/stopwatch.cpp

#include "stopwatch.hpp"

#include <QVariantMap>
#include <algorithm>

namespace {

constexpr int kTickMs = 16;
// 99:59:59.99, the same cap style as the countdown timer.
constexpr qint64 kMaxMs = (99LL * 3600 + 59 * 60 + 59) * 1000 + 990;

} // namespace

Stopwatch::Stopwatch(QObject *parent) : QObject(parent) {
    m_tick.setInterval(kTickMs);
    connect(&m_tick, &QTimer::timeout, this, &Stopwatch::onTick);
}

QString Stopwatch::formatMs(qint64 ms) {
    // Truncate (not round) so the display never runs ahead of real time.
    const qint64 cs = std::max<qint64>(ms, 0) / 10;
    const qint64 c = cs % 100;
    const qint64 totalSecs = cs / 100;
    const qint64 h = totalSecs / 3600;
    const qint64 m = (totalSecs % 3600) / 60;
    const qint64 s = totalSecs % 60;

    if (h > 0) {
        return QStringLiteral("%1:%2:%3.%4")
            .arg(h)
            .arg(m, 2, 10, QChar('0'))
            .arg(s, 2, 10, QChar('0'))
            .arg(c, 2, 10, QChar('0'));
    }
    return QStringLiteral("%1:%2.%3").arg(m, 2, 10, QChar('0')).arg(s, 2, 10, QChar('0')).arg(c, 2, 10, QChar('0'));
}

QString Stopwatch::elapsedText() const {
    return formatMs(m_elapsedMs);
}

QVariantList Stopwatch::laps() const {
    qint64 best = -1, worst = -1;
    if (m_laps.size() >= 2) {
        const auto [mn, mx] = std::minmax_element(m_laps.begin(), m_laps.end(),
                                                  [](const Lap &a, const Lap &b) { return a.lapMs < b.lapMs; });
        best = mn->lapMs;
        worst = mx->lapMs;
    }

    QVariantList out;
    out.reserve(m_laps.size());
    for (int i = static_cast<int>(m_laps.size()) - 1; i >= 0; --i) {
        const Lap &l = m_laps[i];
        QVariantMap row;
        row[QStringLiteral("number")] = i + 1;
        row[QStringLiteral("lapMs")] = l.lapMs;
        row[QStringLiteral("lapText")] = formatMs(l.lapMs);
        row[QStringLiteral("totalMs")] = l.totalMs;
        row[QStringLiteral("totalText")] = formatMs(l.totalMs);
        // If every lap is identical there is no meaningful best or worst.
        row[QStringLiteral("best")] = best >= 0 && best != worst && l.lapMs == best;
        row[QStringLiteral("worst")] = worst >= 0 && best != worst && l.lapMs == worst;
        out.append(row);
    }
    return out;
}

qint64 Stopwatch::currentElapsed() const {
    if (m_state != Running) return m_elapsedMs;
    return std::min(m_baseMs + m_clock.elapsed(), kMaxMs);
}

void Stopwatch::setState(State s) {
    if (m_state == s) return;
    m_state = s;
    emit stateChanged();
}

void Stopwatch::setElapsed(qint64 ms) {
    if (m_elapsedMs == ms) return;
    const QString before = elapsedText();
    m_elapsedMs = ms;
    // Only notify when the visible text changes, so bindings are not
    // re-evaluated on every tick.
    if (before != elapsedText()) emit elapsedChanged();
}

void Stopwatch::start() {
    if (m_state == Running) return;

    if (m_state == Paused) {
        resume();
        return;
    }

    m_baseMs = 0;
    m_clock.start();
    m_tick.start();
    setState(Running);
}

void Stopwatch::pause() {
    if (m_state != Running) return;

    const qint64 now = currentElapsed();
    m_tick.stop();
    setState(Paused);
    setElapsed(now);
}

void Stopwatch::resume() {
    if (m_state != Paused) return;
    if (m_elapsedMs >= kMaxMs) return;

    m_baseMs = m_elapsedMs;
    m_clock.start();
    m_tick.start();
    setState(Running);
}

void Stopwatch::toggle() {
    if (m_state == Running)
        pause();
    else
        start(); // start() handles both Idle and Paused
}

void Stopwatch::lap() {
    if (m_state != Running) return;

    const qint64 total = currentElapsed();
    const qint64 previous = m_laps.isEmpty() ? 0 : m_laps.last().totalMs;
    m_laps.append({total - previous, total});
    setElapsed(total);
    emit lapsChanged();
}

void Stopwatch::reset() {
    m_tick.stop();
    m_baseMs = 0;
    m_elapsedMs = 0;
    const bool hadLaps = !m_laps.isEmpty();
    m_laps.clear();
    setState(Idle);
    emit elapsedChanged();
    if (hadLaps) emit lapsChanged();
}

void Stopwatch::onTick() {
    const qint64 now = currentElapsed();
    setElapsed(now);

    if (now < kMaxMs) return;

    // Hit the display cap: hold at the maximum rather than overflow the format.
    m_tick.stop();
    setState(Paused);
}
