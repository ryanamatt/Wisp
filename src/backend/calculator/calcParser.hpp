// src/backend/calculator/calcParser.hpp
//
// Text -> compiled Equation. No Qt in here.
//
// Grammar, lowest to highest precedence:
//   equation := expr [ relation expr ]
//   expr     := term { ('+' | '-') term }
//   term     := unary { ('*' | '/' | '%') unary | <implicit multiply> power }
//   unary    := ('+' | '-') unary | power
//   power    := postfix [ '^' unary ]            (right associative)
//   postfix  := atom { '!' }
//   atom     := number | x | y | func '(' expr ')' | '(' expr ')'

#pragma once

#include "calcExpression.hpp"
#include "calcLexer.hpp"
#include <string_view>
#include <variant>

namespace wisp::calc {

enum class Relation { None, Eq, Lt, Le, Gt, Ge };

enum class Kind {
    Value,    // no x or y, no relation: "2(3)+1"
    Explicit, // y = f(x), or a bare f(x): the graph is the curve y = f(x)
    Implicit, // anything else with x/y and a relation: "x^2+y^2=1", "y>x"
};

struct Equation {
    Kind kind = Kind::Value;
    Relation rel = Relation::None;

    // Value and Explicit: lhs is the expression to evaluate (the value, or
    // f(x)) and rhs is empty. Implicit: the relation reads  lhs rel rhs.
    Expression lhs;
    Expression rhs;
};

struct ParseOptions {
    // Finish a half-typed expression so it can be previewed while typing:
    // "2(3" becomes "2(3)" and "2+" becomes "2".
    bool autoComplete = false;
};

std::variant<Equation, ParseError> parse(std::string_view text, ParseOptions options = {});

} // namespace wisp::calc
