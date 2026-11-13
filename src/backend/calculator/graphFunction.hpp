// src/backend/calculator/graphFunction.hpp
//
// One Expression in the graph window: "y = 2(x - 2)", "sin(x)", ...

#pragma once

#include "calcParser.hpp"
#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <memory>
#include <qtmetamacros.h>

class GraphFunction : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY changed)
    Q_PROPERTY(bool visible READ isVisible WRITE setVisible NOTIFY changed)
    Q_PROPERTY(bool valid READ valid NOTIFY changed) // True if can draw a graph
    Q_PROPERTY(QString error READ error NOTIFY changed) // Empty when no error

public:
    explicit GraphFunction(QObject *parent = nullptr);

    QString text() const {
        return m_text;
    }

    void setText(const QString &text);

    QColor color() const {
        return m_color;
    }
    void setColor(const QColor &color);

    bool isVisible() const {
        return m_visible;
    }
    void setVisible(bool visible);

    bool valid() const {
        return m_equation != nullptr;
    }
    QString error() const {
        return m_error;
    }

    // y at this x, or NaN when undefined or not drawable.
    Q_INVOKABLE double evaluate(double x) const;

    // Null unless valid() and visible. The returned object is
    // immutable, so it is safe to hold while the text keeps changing.
    std::shared_ptr<const wisp::calc::Equation> equation() const {
        return m_visible ? m_equation : nullptr;
    }

signals:
    void textChanged();
    void changed();

private:
    void recompile();

    QString m_text;
    QColor m_color = QColor("#4c8bf5");
    bool m_visible = true;
    QString m_error;
    std::shared_ptr<const wisp::calc::Equation> m_equation;
};

