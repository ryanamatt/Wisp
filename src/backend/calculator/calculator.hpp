// src/backend/calculator.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <string>
#include <utility>
#include <vector>

// ----- Token Stuff -----
enum class TokenType {
    Number,
    Add,
    Subtract,
    Multiply,
    Divide,
    Modulo,
    Power,
    Sqrt,
    Sin,
    Cos,
    Tan,
    Log,
    Log10,
    LeftParen,
    RightParen,
    Pi,
    E,
};

class Token {
public:
    Token(TokenType token, std::string value) : token(token), value(std::move(value)) {
    }

    TokenType get_token() const {
        return token;
    }
    std::string get_value() const {
        return value;
    }

private:
    TokenType token;
    std::string value;
};

// ----- Calculator -----
class Calculator : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(double answer READ answer)

public:
    explicit Calculator(QObject *parent = nullptr) : QObject(parent) {
    }

    Q_INVOKABLE bool solve(QString equation);

    double answer() const {
        return m_answer;
    }

private:
    void runLexer();
    Token make_number(int &current_pos);
    Token make_identifier(int &current_pos);

    void completeTokens();

    double runParser();
    double parseExpression();
    double parseTerm();
    double parsePower();
    double parseFactor();

    double m_answer = 0.0;
    std::string m_equation;
    std::vector<Token> m_tokens;
    size_t m_parser_pos = 0;
};
