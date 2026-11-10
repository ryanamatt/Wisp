// src/backend/calculator/calcExpression.hpp
//
// A compiled expression: a flat array of nodes, children stored before their parents.

#pragma once

#include <cstdint>
#include <vector>

namespace wisp::calc {

enum class Op : std::uint8_t {
    Const, // value
    VarX,
    VarY,
    Neg,  // -a
    Add,  // a + b
    Sub,  // a - b
    Mul,  // a * b
    Div,  // a / b
    Mod,  // a % b
    Pow,  // a ^ b
    Fact, // a!
    Call, // function #func applied to a
};

struct Node {
    Op op = Op::Const;
    int a = -1;
    int b = -1;
    int func = -1;
    double value = 0.0;
};

class Expression {
public:
    Expression() = default;
    Expression(std::vector<Node> nodes, int root);

    bool empty() const {
        return m_root < 0;
    }
    bool usesX() const {
        return m_usesX;
    }
    bool usesY() const {
        return m_usesY;
    }

    // True if the whole expression is just the variable y.
    bool isBareY() const;

    // Never throws. Domain errors (1/0, sqrt(-1), 2.5!, ...) give NaN.
    // Overflow can give +/-inf, so callers should test with std::isfinite.
    double eval(double x, double y = 0.0) const noexcept;

private:
    double evalNode(int index, double x, double y) const noexcept;

    std::vector<Node> m_nodes;
    int m_root = -1;
    bool m_usesX = false;
    bool m_usesY = false;
};

} // namespace wisp::calc
