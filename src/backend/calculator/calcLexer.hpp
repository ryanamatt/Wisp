// src/backend/calculator/calcLexer.hpp

// Turns text into tokens

#pragma once

#include <string>
#include <string_view>
#include <vector>

namespace wisp::calc {

struct ParseError {
    std::string message;
    int pos = 0; // char index into the original text
};

enum class TokenType {
    Number, // also used for the constants pi and e
    X,
    Y,
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Pow,
    Fact,
    LParen,
    RParen,
    Func, // see Token::func
    Eq,
    Lt,
    Le,
    Gt,
    Ge,
};

struct Token {
    TokenType type = TokenType::Number;
    double value = 0.0; // Number
    int func = -1;      // Func: index into the function table
    int pos = 0;
};

// Throws ParseError on bad input
std::vector<Token> tokenize(std::string_view text);

} // namespace wisp::calc
