// src/backend/convert/convert.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QVariantMap>
#include <qqmlintegration.h>

// QML face of the converter.

class Convert : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Convert(QObject *parent = nullptr) : QObject(parent) {
    }

    // `query` is the text after the Runner's "~". Returns
    //   { ok: bool, input: string, swatch: string,
    //     rows: [ { label, value, copy } ] }
    // When ok is false the other fields are empty.
    Q_INVOKABLE QVariantMap convert(const QString &query) const;
};
