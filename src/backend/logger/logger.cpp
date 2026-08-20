// src/backend/logger/logger.cpp

#include "logger.hpp"
#include "logging/log.hpp"

Logger::Logger(QObject *parent) : QObject(parent) {}

Logger::~Logger() = default;

void Logger::debug(const QString &message) { debug(QString(), message); }
void Logger::info(const QString &message) { info(QString(), message); }
void Logger::warning(const QString &message) { warning(QString(), message); }
void Logger::error(const QString &message) { error(QString(), message); }

void Logger::debug(const QString &category, const QString &message) {
    wisp::log::debug(category.toStdString(), message.toStdString());
    emit messageLogged(Level::Debug, category, message);
}

void Logger::info(const QString &category, const QString &message) {
    wisp::log::info(category.toStdString(), message.toStdString());
    emit messageLogged(Level::Info, category, message);
}

void Logger::warning(const QString &category, const QString &message) {
    wisp::log::warning(category.toStdString(), message.toStdString());
    emit messageLogged(Level::Warning, category, message);
}

void Logger::error(const QString &category, const QString &message) {
    wisp::log::error(category.toStdString(), message.toStdString());
    emit messageLogged(Level::Error, category, message);
}

QString Logger::logFilePath() const {
    return QString::fromStdString(wisp::log::filePath());
}
