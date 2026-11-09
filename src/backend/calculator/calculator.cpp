// src/backend/calculator/calculator.cpp

#include "calculator.hpp"
#include "calcParser.hpp"
#include <cmath>

bool Calculator::solve(QString equation) {
    using namespace wisp::calc;

    ParseOptions options;
    options.autoComplete = true;

    auto parsed = parse(equation.toStdString(), options);
    const Equation *eq = std::get_if<Equation>(&parsed);

    // Only plain numbers count: "x+1" or "y=2" is a graph, not an answer.
    if (!eq || eq->kind != Kind::Value) return false;

    double result = eq->lhs.eval(0.0, 0.0);
    if (!std::isfinite(result)) return false;

    m_answer = result;
    return true;
}
