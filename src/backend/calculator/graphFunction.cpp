// src/backend/calculator/graphFunction.cpp

#include "graphFunction.hpp"
#include <limits>

GraphFunction::GraphFunction(QObject *parent) : QObject(parent) {}

void GraphFunction::setText(const QString &text) {
    if (m_text == text) return;
    m_text = text;
    recompile();
    emit textChanged();
    emit changed();
}

void GraphFunction::setColor(const QColor &color) {
    if (m_color == color) return;
    m_color = color;
    emit changed();
}

void GraphFunction::setVisible(bool visible) {
    if (m_visible == visible) return;
    m_visible = visible;
    emit changed();
}

void GraphFunction::recompile() {
    using namespace wisp::calc;

    m_equation = nullptr;
    m_error.clear();

    if (m_text.trimmed().isEmpty()) return;

    // Autocomplete so curves update while typing ("2(x" draws 2x).
    ParseOptions options;
    options.autoComplete = true;

    auto parsed = parse(m_text.toStdString(), options);

    if (auto *err = std::get_if<ParseError>(&parsed)) {
        m_error = QString::fromStdString(err->message);
        return;
    }

    auto eq = std::make_shared<const Equation>(std::move(std::get<Equation>(parsed)));

    switch (eq->kind) {
        case Kind::Explicit: m_equation = std::move(eq); break;
        case Kind::Implicit: m_error = QStringLiteral("Implicit equations and inequalities are not supported yet"); break;
        case Kind::Value: m_error = QStringLiteral("Nothing to plot (add x, or write y = ...)"); break;
    }
}

double GraphFunction::evaluate(double x) const {
    if (!m_equation) return std::numeric_limits<double>::quiet_NaN();
    return m_equation->lhs.eval(x, 0.0);
}

