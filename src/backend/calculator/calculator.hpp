// src/backend/calculator.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <string>
#include <vector>

enum class TokenType { Number, Add, Subtract, Multiply, Divide };

class Token {
public:
    Token(TokenType token, std::string value, int line = 0) : token(token), value(std::move(value)) {
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

    double runParser();
    double parseExpression();
    double parseTerm();
    double parseFactor();

    double m_answer;
    std::string m_equation;
    std::vector<Token> m_tokens;
    size_t m_parser_pos = 0;
};
