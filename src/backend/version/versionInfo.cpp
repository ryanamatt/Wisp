// src/backend/version/versionInfo.cpp

#include "versionInfo.hpp"
#include "version.hpp"

WispVersion::WispVersion(QObject *parent) : QObject(parent) {
    m_version = QStringLiteral(WISP_VERSION);
}

QString WispVersion::version() const {
    return m_version;        
}