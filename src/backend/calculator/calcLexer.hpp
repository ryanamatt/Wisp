// src/backend/calculator/calcLexer.hpp

// Turn text into tokens

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
    Number, // Includes constants like pi or e
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Pow,
    Fact,
    LParen,
    RParen,
    Func,
};

struct Token {
    TokenType type = TokenType::Number;
    double value = 0.0; // Number
    int func = -1; // Func: index into the function table
    int pos = 0;
};

// Throws ParseError on bad input
std::vector<Token> tokenize(std::string_view text);

} // namespace wisp::calc

