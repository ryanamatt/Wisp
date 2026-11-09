// src/backend/calculator/calcParser.cpp

#include "calcParser.hpp"
#include "calcFunctions.hpp"
#include <string>
#include <utility>

namespace wisp::calc {

namespace {

// True if this token can start a factor that is implicitly multiplied in,
// e.g. the "(3)" in "2(3)", the "x" in "2x", or the "sin" in "2sin(x)".
bool startsImplicitFactor(TokenType type) {
    switch (type) {
        case TokenType::Number:
        case TokenType::X:
        case TokenType::Y:
        case TokenType::LParen:
        case TokenType::Func: return true;
        default: return false;
    }
}

bool isRelation(TokenType type) {
    return type == TokenType::Eq || type == TokenType::Lt || type == TokenType::Le || type == TokenType::Gt ||
           type == TokenType::Ge;
}

Relation toRelation(TokenType type) {
    switch (type) {
        case TokenType::Eq: return Relation::Eq;
        case TokenType::Lt: return Relation::Lt;
        case TokenType::Le: return Relation::Le;
        case TokenType::Gt: return Relation::Gt;
        case TokenType::Ge: return Relation::Ge;
        default: return Relation::None;
    }
}

// Drops dangling pieces that cannot finish an expression (binary operators,
// function names, empty opening parens) and closes any open parentheses.
// Relations are kept on purpose: "y =" is still an error, not a plot of y.
void completeTokens(std::vector<Token> &tokens) {
    while (!tokens.empty()) {
        switch (tokens.back().type) {
            case TokenType::Add:
            case TokenType::Sub:
            case TokenType::Mul:
            case TokenType::Div:
            case TokenType::Mod:
            case TokenType::Pow:
            case TokenType::Func:
            case TokenType::LParen: tokens.pop_back(); continue;
            default: break;
        }
        break;
    }

    // Extra ')' are left alone so the parser rejects them.
    int depth = 0;
    for (const Token &t : tokens) {
        if (t.type == TokenType::LParen)
            depth++;
        else if (t.type == TokenType::RParen && depth > 0)
            depth--;
    }

    int endPos = tokens.empty() ? 0 : tokens.back().pos + 1;
    for (; depth > 0; depth--) {
        Token close;
        close.type = TokenType::RParen;
        close.pos = endPos;
        tokens.push_back(close);
    }
}

class Parser {
public:
    Parser(std::vector<Token> tokens, int textEnd) : m_tokens(std::move(tokens)), m_textEnd(textEnd) {
    }

    Equation parseEquation() {
        Equation eq;

        int lhsRoot = parseExpr();
        Expression lhs = takeExpression(lhsRoot);

        if (atEnd()) {
            if (lhs.usesY()) fail("Use = or an inequality when graphing y");
            eq.kind = lhs.usesX() ? Kind::Explicit : Kind::Value;
            eq.lhs = std::move(lhs);
            return eq;
        }

        if (!isRelation(cur().type)) {
            if (cur().type == TokenType::RParen) fail("Unmatched ')'");
            fail("Unexpected symbol");
        }

        eq.rel = toRelation(cur().type);
        advance();

        int rhsRoot = parseExpr();
        Expression rhs = takeExpression(rhsRoot);

        if (!atEnd()) {
            if (isRelation(cur().type)) fail("Chained relations are not supported");
            if (cur().type == TokenType::RParen) fail("Unmatched ')'");
            fail("Unexpected symbol");
        }

        // y = f(x) (or f(x) = y) is the one shape the graph can draw as a curve.
        if (eq.rel == Relation::Eq && lhs.isBareY() && !rhs.usesY()) {
            eq.kind = Kind::Explicit;
            eq.lhs = std::move(rhs);
        } else if (eq.rel == Relation::Eq && rhs.isBareY() && !lhs.usesY()) {
            eq.kind = Kind::Explicit;
            eq.lhs = std::move(lhs);
        } else {
            eq.kind = Kind::Implicit;
            eq.lhs = std::move(lhs);
            eq.rhs = std::move(rhs);
        }
        return eq;
    }

private:
    // --- token helpers ---
    bool atEnd() const {
        return m_pos >= m_tokens.size();
    }
    const Token &cur() const {
        return m_tokens[m_pos];
    }
    void advance() {
        m_pos++;
    }
    int errorPos() const {
        return atEnd() ? m_textEnd : cur().pos;
    }

    [[noreturn]] void fail(const std::string &message) const {
        throw ParseError{message, errorPos()};
    }

    // --- node helpers ---
    int add(Node n) {
        m_nodes.push_back(n);
        return (int)m_nodes.size() - 1;
    }

    int makeBinary(Op op, int a, int b) {
        Node n;
        n.op = op;
        n.a = a;
        n.b = b;
        return add(n);
    }

    int makeUnary(Op op, int a) {
        Node n;
        n.op = op;
        n.a = a;
        return add(n);
    }

    // Moves the nodes built so far into an Expression and starts a fresh arena.
    Expression takeExpression(int root) {
        Expression e(std::move(m_nodes), root);
        m_nodes.clear();
        return e;
    }

    // --- grammar ---
    int parseExpr() {
        int left = parseTerm();
        while (!atEnd()) {
            TokenType t = cur().type;
            if (t == TokenType::Add) {
                advance();
                left = makeBinary(Op::Add, left, parseTerm());
            } else if (t == TokenType::Sub) {
                advance();
                left = makeBinary(Op::Sub, left, parseTerm());
            } else {
                break;
            }
        }
        return left;
    }

    int parseTerm() {
        int left = parseUnary();
        while (!atEnd()) {
            TokenType t = cur().type;
            if (t == TokenType::Mul) {
                advance();
                left = makeBinary(Op::Mul, left, parseUnary());
            } else if (t == TokenType::Div) {
                advance();
                left = makeBinary(Op::Div, left, parseUnary());
            } else if (t == TokenType::Mod) {
                advance();
                left = makeBinary(Op::Mod, left, parseUnary());
            } else if (startsImplicitFactor(t)) {
                left = makeBinary(Op::Mul, left, parsePower());
            } else {
                break;
            }
        }
        return left;
    }

    // Sign sits above power, so -2^2 is -(2^2) = -4.
    int parseUnary() {
        if (!atEnd()) {
            if (cur().type == TokenType::Sub) {
                advance();
                return makeUnary(Op::Neg, parseUnary());
            }
            if (cur().type == TokenType::Add) {
                advance();
                return parseUnary();
            }
        }
        return parsePower();
    }

    // The exponent is a unary, so 2^-3 works and 2^3^2 is 2^(3^2).
    int parsePower() {
        int base = parsePostfix();
        if (!atEnd() && cur().type == TokenType::Pow) {
            advance();
            return makeBinary(Op::Pow, base, parseUnary());
        }
        return base;
    }

    // Factorial binds tighter than the sign: -3! is -(3!).
    int parsePostfix() {
        int value = parseAtom();
        while (!atEnd() && cur().type == TokenType::Fact) {
            advance();
            value = makeUnary(Op::Fact, value);
        }
        return value;
    }

    int parseAtom() {
        if (atEnd()) fail("Unexpected end of expression");

        const Token token = cur();

        switch (token.type) {
            case TokenType::Number: {
                advance();
                Node n;
                n.op = Op::Const;
                n.value = token.value;
                return add(n);
            }
            case TokenType::X: {
                advance();
                Node n;
                n.op = Op::VarX;
                return add(n);
            }
            case TokenType::Y: {
                advance();
                Node n;
                n.op = Op::VarY;
                return add(n);
            }
            case TokenType::LParen: {
                advance();
                int inner = parseExpr();
                expectRightParen();
                return inner;
            }
            case TokenType::Func: {
                advance();
                if (atEnd() || cur().type != TokenType::LParen) {
                    fail("Expected '(' after " + std::string(functionAt(token.func).name));
                }
                advance();
                int arg = parseExpr();
                expectRightParen();

                Node n;
                n.op = Op::Call;
                n.a = arg;
                n.func = token.func;
                return add(n);
            }
            default: fail("Unexpected symbol");
        }
    }

    void expectRightParen() {
        if (atEnd() || cur().type != TokenType::RParen) fail("Missing closing ')'");
        advance();
    }

    std::vector<Token> m_tokens;
    int m_textEnd;
    size_t m_pos = 0;
    std::vector<Node> m_nodes;
};

} // namespace

std::variant<Equation, ParseError> parse(std::string_view text, ParseOptions options) {
    try {
        std::vector<Token> tokens = tokenize(text);
        if (tokens.empty()) return ParseError{"Empty expression", 0};

        if (options.autoComplete) {
            completeTokens(tokens);
            if (tokens.empty()) return ParseError{"Incomplete expression", (int)text.size()};
        }

        Parser parser(std::move(tokens), (int)text.size());
        return parser.parseEquation();
    } catch (const ParseError &e) { return e; }
}

} // namespace wisp::calc
