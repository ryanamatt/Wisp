// src/backend/convert/convert.cpp

#include "convert.hpp"
#include "convertCore.hpp"
#include <QVariantList>

QVariantMap Convert::convert(const QString &query) const {
    QVariantMap out;
    out.insert(QStringLiteral("ok"), false);
    out.insert(QStringLiteral("input"), QString());
    out.insert(QStringLiteral("swatch"), QString());
    out.insert(QStringLiteral("rows"), QVariantList());

    // Nothing in the core throws, but an exception escaping a Q_INVOKABLE
    // would take the whole shell down, so be safe.
    try {
        const wisp::convert::Result r = wisp::convert::run(query.toStdString());
        if (!r.ok) return out;

        QVariantList rows;
        for (const wisp::convert::Row &row : r.rows) {
            QVariantMap m;
            m.insert(QStringLiteral("label"), QString::fromStdString(row.label));
            m.insert(QStringLiteral("value"), QString::fromStdString(row.value));
            m.insert(QStringLiteral("copy"), QString::fromStdString(row.copy));
            rows.append(m);
        }

        out.insert(QStringLiteral("ok"), true);
        out.insert(QStringLiteral("input"), QString::fromStdString(r.input));
        out.insert(QStringLiteral("swatch"), QString::fromStdString(r.swatch));
        out.insert(QStringLiteral("rows"), rows);
    } catch (...) {}
    return out;
}
