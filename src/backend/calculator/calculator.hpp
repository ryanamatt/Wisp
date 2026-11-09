// src/backend/calculator/calculator.hpp

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

class Calculator : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(double answer READ answer)

public:
    explicit Calculator(QObject *parent = nullptr) : QObject(parent) {
    }

    // Returns true and updates answer if the text is a finite number.
    // Half-typed input like "2(3" is completed so it can be previewed.
    Q_INVOKABLE bool solve(QString equation);

    double answer() const {
        return m_answer;
    }

private:
    double m_answer = 0.0;
};
