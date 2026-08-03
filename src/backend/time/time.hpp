// backend/time/time.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTimer>

class Time : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString time READ time NOTIFY timeChanged)

public:
    explicit Time(QObject *parent = nullptr);

    QString time() const;

signals:
    void timeChanged();

private slots:
    void updateTime();

private:
    QTimer m_timer;
    QString m_time;
};