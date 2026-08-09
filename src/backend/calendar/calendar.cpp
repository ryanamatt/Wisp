// backend/calendar/calendar.cpp

#include "calendar.hpp"

#include <QLocale>

namespace {

constexpr int kGridRows = 6;
constexpr int kGridCols = 7;
constexpr int kGridCells = kGridRows * kGridCols;

// How far ahead we ask gcalcli to search when building the "upcoming"
// list. We take the first `m_maxUpcoming` events out of whatever comes
// back, so this just needs to comfortably cover a typical calendar.
constexpr int kUpcomingSearchDays = 60;

constexpr int kDefaultMaxUpcoming = 8;

// Keeps the popup's data from going stale if it's left open a while.
// gcalcli hits the network, so this stays well above Time's 1s tick.
constexpr int kRefreshIntervalMs = 5 * 60 * 1000;

// First cell of a Sunday-first 6-week grid that fully contains `month`.
QDate gridStartFor(int year, int month) {
    const QDate firstOfMonth(year, month, 1);
    // QDate::dayOfWeek(): Monday=1..Sunday=7. Mod 7 turns that into a
    // Sunday-first offset (Sunday=0, Monday=1, ... Saturday=6).
    const int offset = firstOfMonth.dayOfWeek() % 7;
    return firstOfMonth.addDays(-offset);
}

} // namespace

Calendar::Calendar(QObject *parent) : QObject(parent) {
    const QDate today = QDate::currentDate();
    m_displayedYear = today.year();
    m_displayedMonth = today.month();

    m_maxUpcoming = qEnvironmentVariableIntValue("WISP_CALENDAR_UPCOMING_COUNT");
    if (m_maxUpcoming <= 0) m_maxUpcoming = kDefaultMaxUpcoming;

    connect(&m_monthProcess, &QProcess::finished, this, [this](int, QProcess::ExitStatus) {
        m_monthLoading = false;
        m_monthEvents = parseTsv(m_monthProcess.readAllStandardOutput());
        rebuildMonthGrid();
        emit loadingChanged();
    });
    connect(&m_monthProcess, &QProcess::errorOccurred, this, [this](QProcess::ProcessError err) {
        if (err == QProcess::FailedToStart) {
            setError("gcalcli not found on PATH. Is it installed?");
        }
        m_monthLoading = false;
        emit loadingChanged();
    });

    connect(&m_upcomingProcess, &QProcess::finished, this, [this](int, QProcess::ExitStatus) {
        m_upcomingLoading = false;

        const QList<CalendarEvent> events = parseTsv(m_upcomingProcess.readAllStandardOutput());

        QVariantList list;
        for (const CalendarEvent &event : events) {
            if (list.size() >= m_maxUpcoming) break;

            QVariantMap map;
            map["title"] = event.title;
            map["startDate"] = event.startDate.toString(Qt::ISODate);
            map["startTime"] = event.startTime;
            map["endDate"] = event.endDate.toString(Qt::ISODate);
            map["endTime"] = event.endTime;
            map["allDay"] = event.isAllDay();
            list.append(map);
        }

        m_upcomingEvents = list;
        emit upcomingEventsChanged();
        emit loadingChanged();
    });
    connect(&m_upcomingProcess, &QProcess::errorOccurred, this, [this](QProcess::ProcessError err) {
        if (err == QProcess::FailedToStart) {
            setError("gcalcli not found on PATH. Is it installed?");
        }
        m_upcomingLoading = false;
        emit loadingChanged();
    });

    rebuildMonthGrid(); // empty grid immediately so layout doesn't jump
    refresh();

    m_refreshTimer.setInterval(kRefreshIntervalMs);
    connect(&m_refreshTimer, &QTimer::timeout, this, &Calendar::refresh);
    m_refreshTimer.start();
}

QString Calendar::displayedMonthName() const {
    const QDate d(m_displayedYear, m_displayedMonth, 1);
    return QLocale::system().toString(d, "MMMM yyyy");
}

QVariantList Calendar::monthDays() const {
    return m_monthDays;
}

QVariantList Calendar::upcomingEvents() const {
    return m_upcomingEvents;
}

bool Calendar::loading() const {
    return m_monthLoading || m_upcomingLoading;
}

QString Calendar::error() const {
    return m_error;
}

bool Calendar::isCurrentMonth() const {
    const QDate today = QDate::currentDate();
    return today.year() == m_displayedYear && today.month() == m_displayedMonth;
}

void Calendar::nextMonth() {
    m_displayedMonth++;
    if (m_displayedMonth > 12) {
        m_displayedMonth = 1;
        m_displayedYear++;
    }

    emit monthChanged();
    rebuildMonthGrid();
    fetchMonthEvents();
}

void Calendar::previousMonth() {
    m_displayedMonth--;
    if (m_displayedMonth < 1) {
        m_displayedMonth = 12;
        m_displayedYear--;
    }

    emit monthChanged();
    rebuildMonthGrid();
    fetchMonthEvents();
}

void Calendar::goToToday() {
    const QDate today = QDate::currentDate();
    const bool changed = today.year() != m_displayedYear || today.month() != m_displayedMonth;

    m_displayedYear = today.year();
    m_displayedMonth = today.month();

    if (changed) {
        emit monthChanged();
        rebuildMonthGrid();
        fetchMonthEvents();
    }
}

void Calendar::refresh() {
    fetchMonthEvents();
    fetchUpcomingEvents();
}

void Calendar::fetchMonthEvents() {
    if (m_monthProcess.state() != QProcess::NotRunning) return;

    const QDate gridStart = gridStartFor(m_displayedYear, m_displayedMonth);
    const QDate gridEnd = gridStart.addDays(kGridCells); // exclusive end

    m_monthLoading = true;
    emit loadingChanged();

    const QStringList args{
        "--nocolor", "agenda",
        gridStart.toString(Qt::ISODate),
        gridEnd.toString(Qt::ISODate),
        "--tsv",
    };
    m_monthProcess.start("gcalcli", args);
}

void Calendar::fetchUpcomingEvents() {
    if (m_upcomingProcess.state() != QProcess::NotRunning) return;

    const QDate today = QDate::currentDate();
    const QDate rangeEnd = today.addDays(kUpcomingSearchDays);

    m_upcomingLoading = true;
    emit loadingChanged();

    const QStringList args{
        "--nocolor", "agenda",
        today.toString(Qt::ISODate),
        rangeEnd.toString(Qt::ISODate),
        "--tsv",
    };
    m_upcomingProcess.start("gcalcli", args);
}

void Calendar::rebuildMonthGrid() {
    const QDate today = QDate::currentDate();
    const QDate gridStart = gridStartFor(m_displayedYear, m_displayedMonth);

    QVariantList days;
    days.reserve(kGridCells);

    for (int i = 0; i < kGridCells; ++i) {
        const QDate cellDate = gridStart.addDays(i);

        bool hasEvents = false;
        for (const CalendarEvent &event : m_monthEvents) {
            if (cellDate >= event.startDate && cellDate <= event.endDate) {
                hasEvents = true;
                break;
            }
        }

        QVariantMap cell;
        cell["date"] = cellDate.toString(Qt::ISODate);
        cell["day"] = cellDate.day();
        cell["inMonth"] = cellDate.month() == m_displayedMonth;
        cell["isToday"] = cellDate == today;
        cell["hasEvents"] = hasEvents;
        days.append(cell);
    }

    m_monthDays = days;
    emit monthDaysChanged();
}

QList<Calendar::CalendarEvent> Calendar::parseTsv(const QByteArray &data) {
    QList<CalendarEvent> events;

    const QString text = QString::fromUtf8(data);
    const QStringList lines = text.split('\n', Qt::SkipEmptyParts);

    for (const QString &line : lines) {
        const QStringList parts = line.split('\t');
        if (parts.size() < 5) continue;

        const QDate startDate = QDate::fromString(parts[0], Qt::ISODate);
        if (!startDate.isValid()) continue;

        CalendarEvent event;
        event.startDate = startDate;
        event.startTime = parts[1];
        event.endDate = QDate::fromString(parts[2], Qt::ISODate);
        if (!event.endDate.isValid()) event.endDate = startDate;
        event.endTime = parts[3];
        event.title = parts.mid(4).join('\t');

        if (event.isAllDay() && event.endDate > event.startDate) {
            event.endDate = event.endDate.addDays(-1);
        }

        events.append(event);
    }

    return events;
}

void Calendar::setError(const QString &message) {
    if (m_error != message) {
        m_error = message;
        emit errorChanged();
    }
}
