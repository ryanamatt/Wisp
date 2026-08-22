// src/backend/version/versionInfo.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

class WispVersion : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString version READ version CONSTANT)

public:
    explicit WispVersion(QObject *parent = nullptr);

    QString version() const;

private:
    QString m_version;
};