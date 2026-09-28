// src/backend/calculator.cpp

#include "calculator.hpp"
#include <cctype>
#include <iostream>
#include <stdexcept>
#include <unordered_map>

bool Calculator::solve(QString equation) {
    m_equation = equation.toStdString();
    m_tokens.clear();
    m_parser_pos = 0;

    runLexer();

    try {
        m_answer = runParser();
        return true;
    } catch (const std::exception &e) { return false; }
}

void Calculator::runLexer() {
    std::unordered_map<char, TokenType> symbol_map = {
        {'+', TokenType::Add},
        {'-', TokenType::Subtract},
        {'*', TokenType::Multiply},
        {'/', TokenType::Divide},
    };

    int current_pos = 0;

    while (current_pos < (int)m_equation.size()) {
        char ch = m_equation[current_pos];

        if (std::isspace(ch))
            current_pos++;

        else if (std::isdigit(ch) || ch == '.')
            m_tokens.push_back(this->make_number(current_pos));

        else if (symbol_map.find(ch) != symbol_map.end()) {
            m_tokens.push_back(Token(symbol_map[ch], std::string(1, ch)));
            current_pos++;
        }

        else
            current_pos++; // Skip unknown characters
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

// --- Parser Implementation ---

double Calculator::runParser() {
    if (m_tokens.empty()) return 0.0;
    m_parser_pos = 0;
    return parseExpression();
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
    double result = parseFactor();

    while (m_parser_pos < m_tokens.size()) {
        TokenType type = m_tokens[m_parser_pos].get_token();
        if (type == TokenType::Multiply) {
            m_parser_pos++;
            result *= parseFactor();
        }

        else if (type == TokenType::Divide) {
            m_parser_pos++;
            double divisor = parseFactor();
            if (divisor == 0.0) { throw std::runtime_error("Division by zero"); }
            result /= divisor;
        }

        else {
            break;
        }
    }
    return result;
}

// Handles atomic units (Numbers)
double Calculator::parseFactor() {
    if (m_parser_pos >= m_tokens.size()) { throw std::runtime_error("Unexpected end of expression"); }

    Token token = m_tokens[m_parser_pos];
    if (token.get_token() == TokenType::Number) {
        m_parser_pos++;
        return std::stod(token.get_value());
    }

    throw std::runtime_error("Unexpected token in expression");
}
