// src/backend/logger/logger.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

class Logger : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum class Level { Debug, Info, Warning, Error };
    Q_ENUM(Level)

    explicit Logger(QObject *parent = nullptr);
    ~Logger() override;

    // Single-argument overloads log under the "wisp" category.
    Q_INVOKABLE void debug(const QString &message);
    Q_INVOKABLE void info(const QString &message);
    Q_INVOKABLE void warning(const QString &message);
    Q_INVOKABLE void error(const QString &message);

    // Two-argument overloads let a QML component tag its own messages,
    // e.g. Log.info("Battery", "charging started").
    Q_INVOKABLE void debug(const QString &category, const QString &message);
    Q_INVOKABLE void info(const QString &category, const QString &message);
    Q_INVOKABLE void warning(const QString &category, const QString &message);
    Q_INVOKABLE void error(const QString &category, const QString &message);

    // Path the log file was opened at, useful for a "show logs" action.
    Q_INVOKABLE QString logFilePath() const;

signals:
    // Emitted after every write, in case a QML log-viewer widget wants
    // a live view instead of tailing the file.
    void messageLogged(Level level, const QString &category, const QString &message);
};
