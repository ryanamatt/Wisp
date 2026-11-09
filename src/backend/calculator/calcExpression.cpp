// src/backend/calculator/calcExpression.cpp

#include "calcExpression.hpp"
#include "calcFunctions.hpp"
#include <cmath>
#include <limits>
#include <utility>

namespace wisp::calc {

namespace {

constexpr double kNaN = std::numeric_limits<double>::quiet_NaN();

double factorial(double n) {
    // NaN fails the comparison below, so it also lands here.
    if (!(n >= 0.0) || n != std::floor(n) || n > 170.0) return kNaN;

    double result = 1.0;
    for (int i = 2; i <= (int)n; i++) result *= i;
    return result;
}

} // namespace

Expression::Expression(std::vector<Node> nodes, int root) : m_nodes(std::move(nodes)), m_root(root) {
    for (const Node &n : m_nodes) {
        if (n.op == Op::VarX) m_usesX = true;
        if (n.op == Op::VarY) m_usesY = true;
    }
}

bool Expression::isBareY() const { return m_nodes.size() == 1 && m_nodes[0].op == Op::VarY; }

double Expression::eval(double x, double y) const noexcept {
    if (m_root < 0) return kNaN;
    return evalNode(m_root, x, y);
}

double Expression::evalNode(int index, double x, double y) const noexcept {
    const Node &n = m_nodes[(size_t)index];

    switch (n.op) {
        case Op::Const: return n.value;
        case Op::VarX: return x;
        case Op::VarY: return y;
        case Op::Neg: return -evalNode(n.a, x, y);
        case Op::Add: return evalNode(n.a, x, y) + evalNode(n.b, x, y);
        case Op::Sub: return evalNode(n.a, x, y) - evalNode(n.b, x, y);
        case Op::Mul: return evalNode(n.a, x, y) * evalNode(n.b, x, y);
        case Op::Div: {
            double a = evalNode(n.a, x, y);
            double b = evalNode(n.b, x, y);
            return b == 0.0 ? kNaN : a / b;
        }
        case Op::Mod: {
            double a = evalNode(n.a, x, y);
            double b = evalNode(n.b, x, y);
            return b == 0.0 ? kNaN : std::fmod(a, b);
        }
        case Op::Pow: return std::pow(evalNode(n.a, x, y), evalNode(n.b, x, y));
        case Op::Fact: return factorial(evalNode(n.a, x, y));
        case Op::Call: return functionAt(n.func).fn(evalNode(n.a, x, y));
    }
    return kNaN;
}

} // namespace wisp::calc
