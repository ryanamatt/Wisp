// src/backend/calculator.cpp

#include "calculator.hpp"
#include <cctype>
#include <cmath>
#include <stdexcept>
#include <unordered_map>

namespace {
// True if this token can begin a factor that may be implicitly multiplied,
// e.g. the "(3)" in "2(3)", the "pi" in "2pi", or the "sin" in "2sin(x)".
bool startsImplicitFactor(TokenType type) {
    switch (type) {
    case TokenType::Number:
    case TokenType::LeftParen:
    case TokenType::Pi:
    case TokenType::E:
    case TokenType::Sqrt:
    case TokenType::Sin:
    case TokenType::Cos:
    case TokenType::Tan:
        return true;
    default:
        return false;
    }
}
} // namespace

bool Calculator::solve(QString equation) {
    m_equation = equation.toStdString();
    m_tokens.clear();
    m_parser_pos = 0;

    // The lexer throws too (bad numbers, unknown characters), so it must be
    // inside the try. An exception escaping a Q_INVOKABLE would crash the shell.
    try {
        runLexer();
        completeTokens();

        double result = runParser();
        if (!std::isfinite(result)) { throw std::runtime_error("Result is not finite"); }

        m_answer = result;
        return true;
    } catch (const std::exception &) { return false; }
}

void Calculator::runLexer() {
    std::unordered_map<char, TokenType> symbol_map = {
        {'+', TokenType::Add},    {'-', TokenType::Subtract}, {'*', TokenType::Multiply},  {'/', TokenType::Divide},
        {'%', TokenType::Modulo}, {'^', TokenType::Power},    {'(', TokenType::LeftParen}, {')', TokenType::RightParen},
    };

    int current_pos = 0;

    while (current_pos < (int)m_equation.size()) {
        char ch = m_equation[current_pos];

        if (std::isspace(ch))
            current_pos++;

        else if (std::isdigit(ch) || ch == '.')
            m_tokens.push_back(this->make_number(current_pos));

        else if (std::isalpha(ch))
            m_tokens.push_back(this->make_identifier(current_pos));

        else if (symbol_map.find(ch) != symbol_map.end()) {
            m_tokens.push_back(Token(symbol_map[ch], std::string(1, ch)));
            current_pos++;
        }

        else
            throw std::runtime_error("Unknown character in expression");
    }
}

Token Calculator::make_number(int &current_pos) {
    std::string num_str;
    int dot_count = 0;

    while (current_pos < (int)m_equation.size() &&
           (std::isdigit(m_equation[current_pos]) || m_equation[current_pos] == '.')) {
        if (m_equation[current_pos] == '.') {
            dot_count++;
            if (dot_count > 1) { throw std::runtime_error("Multiple decimal points in number"); }
        }

        num_str += m_equation[current_pos];
        current_pos++;
    }

    if (!num_str.empty() && num_str.back() == '.') { throw std::runtime_error("Trailing decimal point"); }

    return Token(TokenType::Number, num_str);
}

Token Calculator::make_identifier(int &current_pos) {
    std::string ident_str;

    while (current_pos < (int)m_equation.size() && std::isalpha(m_equation[current_pos])) {
        ident_str += std::tolower(m_equation[current_pos]);
        current_pos++;
    }

    if (ident_str == "sqrt") {
        return Token(TokenType::Sqrt, ident_str);
    } else if (ident_str == "sin") {
        return Token(TokenType::Sin, ident_str);
    } else if (ident_str == "cos") {
        return Token(TokenType::Cos, ident_str);
    } else if (ident_str == "tan") {
        return Token(TokenType::Tan, ident_str);
    }

    else if (ident_str == "pi") {
        return Token(TokenType::Pi, ident_str);
    }
    else if (ident_str == "e") {
        return Token(TokenType::E, ident_str);
    }

    throw std::runtime_error("Unknown function or identifier: " + ident_str);
}

// Makes a half-typed expression solvable so the answer can be previewed while
// typing (like Desmos): "2(3" becomes "2(3)", and "2+" becomes "2".
void Calculator::completeTokens() {
    if (m_tokens.empty()) return;

    // Drop anything dangling at the end that cannot finish an expression:
    // binary operators, function names, and an opening paren with nothing in it.
    while (!m_tokens.empty()) {
        switch (m_tokens.back().get_token()) {
        case TokenType::Add:
        case TokenType::Subtract:
        case TokenType::Multiply:
        case TokenType::Divide:
        case TokenType::Modulo:
        case TokenType::Power:
        case TokenType::Sqrt:
        case TokenType::Sin:
        case TokenType::Cos:
        case TokenType::Tan:
        case TokenType::LeftParen:
            m_tokens.pop_back();
            continue;
        default:
            break;
        }
        break;
    }

    // Nothing usable was typed yet, e.g. just "(" or "sin(".
    if (m_tokens.empty()) { throw std::runtime_error("Incomplete expression"); }

    // Close any parentheses that are still open. Extra ')' are left alone so
    // the parser rejects them.
    int depth = 0;
    for (const Token &t : m_tokens) {
        if (t.get_token() == TokenType::LeftParen) depth++;
        else if (t.get_token() == TokenType::RightParen && depth > 0) depth--;
    }
    for (; depth > 0; depth--) { m_tokens.push_back(Token(TokenType::RightParen, ")")); }
}

// --- Parser Implementation ---

double Calculator::runParser() {
    if (m_tokens.empty()) return 0.0;
    m_parser_pos = 0;

    double result = parseExpression();

    // Everything must be consumed, otherwise input like "5 3" would quietly give 5.
    if (m_parser_pos != m_tokens.size()) { throw std::runtime_error("Unexpected token after expression"); }

    return result;
}

// Handles Addition and Subtraction (Lowest precedence)
double Calculator::parseExpression() {
    double result = parseTerm();

    while (m_parser_pos < m_tokens.size()) {
        TokenType type = m_tokens[m_parser_pos].get_token();
        if (type == TokenType::Add) {
            m_parser_pos++;
            result += parseTerm();
        }

        else if (type == TokenType::Subtract) {
            m_parser_pos++;
            result -= parseTerm();
        }

        else {
            break;
        }
    }
    return result;
}

// Handles Multiplication and Division (Higher precedence)
double Calculator::parseTerm() {
    double result = parsePower();

    while (m_parser_pos < m_tokens.size()) {
        TokenType type = m_tokens[m_parser_pos].get_token();
        if (type == TokenType::Multiply) {
            m_parser_pos++;
            result *= parsePower();
        }

        else if (type == TokenType::Divide) {
            m_parser_pos++;
            double divisor = parsePower();
            if (divisor == 0.0) { throw std::runtime_error("Division by zero"); }
            result /= divisor;
        }

        else if (type == TokenType::Modulo) {
            m_parser_pos++;
            double divisor = parsePower();
            if (divisor == 0.0) { throw std::runtime_error("Division by zero"); }
            result = std::fmod(result, divisor);
        }

        // Implicit multiplication: 2(3), (2)(3), 2pi, 2sin(x)
        else if (startsImplicitFactor(type)) {
            result *= parsePower();
        }

        else {
            break;
        }
    }
    return result;
}

// Handles Exponentiation (Right-associative)
double Calculator::parsePower() {
    double base = parseFactor();

    if (m_parser_pos < m_tokens.size() && m_tokens[m_parser_pos].get_token() == TokenType::Power) {
        m_parser_pos++;
        double exponent = parsePower(); // Recursive call ensures right-associativity
        return std::pow(base, exponent);
    }

    return base;
}

// Handles atomic units (Numbers) and parenthesized sub-expressions, including leading unary signs
double Calculator::parseFactor() {
    bool negative = false;

    while (m_parser_pos < m_tokens.size()) {
        TokenType type = m_tokens[m_parser_pos].get_token();
        if (type == TokenType::Subtract)
            negative = !negative;
        else if (type != TokenType::Add)
            break;
        m_parser_pos++;
    }

    if (m_parser_pos >= m_tokens.size()) { throw std::runtime_error("Unexpected end of expression"); }

    Token token = m_tokens[m_parser_pos];

    // Handle functions: sqrt, sin, cos, tan
    TokenType t_type = token.get_token();
    if (t_type == TokenType::Sqrt || t_type == TokenType::Sin || t_type == TokenType::Cos || t_type == TokenType::Tan) {
        std::string func_name = token.get_value();
        m_parser_pos++; // Consume function token

        if (m_parser_pos >= m_tokens.size() || m_tokens[m_parser_pos].get_token() != TokenType::LeftParen) {
            throw std::runtime_error("Expected '(' after " + func_name);
        }
        m_parser_pos++; // Consume '('

        double result = parseExpression();

        if (m_parser_pos >= m_tokens.size() || m_tokens[m_parser_pos].get_token() != TokenType::RightParen) {
            throw std::runtime_error("Mismatched parentheses: expected ')' after " + func_name);
        }
        m_parser_pos++; // Consume ')'

        double val = 0.0;
        if (t_type == TokenType::Sqrt) {
            if (result < 0.0) { throw std::runtime_error("Square root of negative number"); }
            val = std::sqrt(result);
        }

        else if (t_type == TokenType::Sin)
            val = std::sin(result);
        else if (t_type == TokenType::Cos)
            val = std::cos(result);
        else if (t_type == TokenType::Tan)
            val = std::tan(result);

        return negative ? -val : val;
    }

    // Handle parentheses: ( expression )
    if (token.get_token() == TokenType::LeftParen) {
        m_parser_pos++; // Consume '('
        double result = parseExpression();

        if (m_parser_pos >= m_tokens.size() || m_tokens[m_parser_pos].get_token() != TokenType::RightParen) {
            throw std::runtime_error("Mismatched parentheses: expected ')'");
        }
        m_parser_pos++; // Consume ')'
        return negative ? -result : result;
    }

    // Handle regular numbers
    if (token.get_token() == TokenType::Number) {
        m_parser_pos++;
        double value = std::stod(token.get_value());
        return negative ? -value : value;
    }

    if (token.get_token() == TokenType::Pi) {
        m_parser_pos++;
        return M_PI;
    }

    if (token.get_token() == TokenType::E) {
        m_parser_pos++;
        return M_E;
    }

    throw std::runtime_error("Unexpected token in expression");
}
