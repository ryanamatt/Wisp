#include "time.hpp"

#include <QDateTime>

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
    // Same format string the old QML singleton used with Qt.formatDateTime.
    const QString formatted = QDateTime::currentDateTime().toString(QStringLiteral("ddd MMM d hh:mm:ss AP"));

    if (formatted != m_time) {
        m_time = formatted;
        emit timeChanged();
    }
}