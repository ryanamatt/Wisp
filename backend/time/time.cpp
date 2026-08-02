// backend/time/time.cpp

#include "time.hpp"

#include <QDateTime>

#include "env.hpp"

namespace {

// Last-resort fallback for if WISP_TIME_FORMAT isn't set at all.
constexpr const char *kFallbackFormat = "ddd MMM d hh:mm:ss AP";

} // namespace

Time::Time(QObject *parent) : QObject(parent) {
    updateTime();

    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &Time::updateTime);
    m_timer.start();
}

QString Time::time() const {
    return m_time;
}

void Time::updateTime() {
    const QString format = qEnvironmentVariable(wisp::env::kTimeFormat, kFallbackFormat);
    const QString formatted = QDateTime::currentDateTime().toString(format);

    if (formatted != m_time) {
        m_time = formatted;
        emit timeChanged();
    }
}
