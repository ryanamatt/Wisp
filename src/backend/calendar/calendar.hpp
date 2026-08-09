// backend/calendar/calendar.hpp

#pragma once

#include <QDate>
#include <QList>
#include <QObject>
#include <QProcess>
#include <QQmlEngine>
#include <QString>
#include <QTimer>
#include <QVariantList>

class Calendar : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString displayedMonthName READ displayedMonthName NOTIFY monthChanged)

    // 42 cells (6 weeks x 7 days, Sunday-first) covering the displayed
    // month plus the leading/trailing days needed to fill the grid.
    // Each entry: { date, day, inMonth, isToday, hasEvents }
    Q_PROPERTY(QVariantList monthDays READ monthDays NOTIFY monthDaysChanged)

    // Flat, chronological list of the next few events from right now,
    // regardless of which month is currently displayed.
    // Each entry: { title, startDate, startTime, endDate, endTime, allDay }
    Q_PROPERTY(QVariantList upcomingEvents READ upcomingEvents NOTIFY upcomingEventsChanged)

    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(bool isCurrentMonth READ isCurrentMonth NOTIFY monthChanged)

public:
    explicit Calendar(QObject *parent = nullptr);

    QString displayedMonthName() const;
    QVariantList monthDays() const;
    QVariantList upcomingEvents() const;
    bool loading() const;
    QString error() const;
    bool isCurrentMonth() const;

    // Navigate the grid. Only re-fetches the month's events, not upcoming.
    Q_INVOKABLE void nextMonth();
    Q_INVOKABLE void previousMonth();
    Q_INVOKABLE void goToToday();

    // Re-fetches both the displayed month and the upcoming list.
    Q_INVOKABLE void refresh();

signals:
    void monthChanged();
    void monthDaysChanged();
    void upcomingEventsChanged();
    void loadingChanged();
    void errorChanged();

private:
    struct CalendarEvent {
        QDate startDate;
        QString startTime; // "HH:mm", empty for all-day events
        QDate endDate;
        QString endTime;
        QString title;

        bool isAllDay() const { return startTime.isEmpty(); }
    };

    void fetchMonthEvents();
    void fetchUpcomingEvents();
    void rebuildMonthGrid();
    void setError(const QString &message);

    static QList<CalendarEvent> parseTsv(const QByteArray &data);

    int m_displayedYear;
    int m_displayedMonth; // 1-12

    QVariantList m_monthDays;
    QVariantList m_upcomingEvents;
    QList<CalendarEvent> m_monthEvents;

    bool m_monthLoading = false;
    bool m_upcomingLoading = false;
    QString m_error;
    int m_maxUpcoming;

    QProcess m_monthProcess;
    QProcess m_upcomingProcess;
    QTimer m_refreshTimer;
};
