// src/backend/calculator/calcLexer.cpp

#include "calcLexer.hpp"
#include "calcFunctions.hpp"
#include <cctype>
#include <charconv>
#include <string>

namespace wisp::calc {

namespace {

constexpr double kPi = 3.14159265358979323846;
constexpr double kE  = 2.71828182845904523536;

// Protects the recursive parser and evaluator from absurd input.
constexpr size_t kMaxTokens = 2000;

bool isDigit(char c) { return std::isdigit((unsigned char)c) != 0; }
bool isAlpha(char c) { return std::isalpha((unsigned char)c) != 0; }

// One name the lexer can pull out of a run of letters.
struct Word {
    std::string_view name;
    TokenType type;
    int func;
    double value;
};

// Longest known word that starts at text[0], so "2pie" is pi then e.
// Returns false if nothing matches.
bool matchWord(std::string_view text, Word &out) {
    bool found = false;
    auto consider = [&](std::string_view name, TokenType type, int func, double value) {
        if (name.size() <= text.size() && text.substr(0, name.size()) == name &&
            (!found || name.size() > out.name.size())) {
            out = {name, type, func, value};
            found = true;
        }
    };

    consider("pi", TokenType::Number, -1, kPi);
    consider("e", TokenType::Number, -1, kE);
    for (int i = 0; i < functionCount(); i++) consider(functionAt(i).name, TokenType::Func, i, 0.0);

    return found;
}

[[noreturn]] void fail(const char *message, int pos) { throw ParseError{message, pos}; }

} // namespace

std::vector<Token> tokenize(std::string_view text) {
    std::vector<Token> tokens;
    size_t i = 0;

    auto push = [&](TokenType type, size_t pos) {
        Token t;
        t.type = type;
        t.pos = (int)pos;
        tokens.push_back(t);
    };

    while (i < text.size()) {
        char ch = text[i];

        if (std::isspace((unsigned char)ch)) {
            i++;
            continue;
        }

        if (tokens.size() > kMaxTokens) fail("Expression is too long", (int)i);

        if (isDigit(ch) || ch == '.') {
            size_t start = i;
            int dots = 0;
            while (i < text.size() && (isDigit(text[i]) || text[i] == '.')) {
                if (text[i] == '.' && ++dots > 1) fail("Multiple decimal points in number", (int)i);
                i++;
            }
            if (text[i - 1] == '.' && i - start == 1) fail("Lone decimal point", (int)start);
            if (text[i - 1] == '.') fail("Trailing decimal point", (int)i - 1);

            Token t;
            t.type = TokenType::Number;
            t.pos = (int)start;
            std::from_chars(text.data() + start, text.data() + i, t.value);
            tokens.push_back(t);
            continue;
        }

        if (isAlpha(ch)) {
            size_t runEnd = i;
            std::string run;
            while (runEnd < text.size() && isAlpha(text[runEnd])) {
                run += (char)std::tolower((unsigned char)text[runEnd]);
                runEnd++;
            }

            size_t offset = 0;
            while (offset < run.size()) {
                Word w;
                if (!matchWord(std::string_view(run).substr(offset), w))
                    fail("Unknown Function or identifier.", (int)(i + offset));

                Token t;
                t.type = w.type;
                t.func = w.func;
                t.value = w.value;
                t.pos = (int)(i + offset);
                offset += w.name.size();

                // Letters stop at digits, so "log10" arrives as "log" then "10"
                if (w.name == "log" && offset == run.size() && runEnd + 1 < text.size() &&
                        text[runEnd] == '1' && text[runEnd + 1] == '0') {
                    runEnd +=2;
                    t.func = findFunction("log10");
                }

                tokens.push_back(t);
            }
            i = runEnd;
            continue;
        }

        switch (ch) {
            case '+': push(TokenType::Add, i); break;
            case '-': push(TokenType::Sub, i); break;
            case '*': push(TokenType::Mul, i); break;
            case '/': push(TokenType::Div, i); break;
            case '%': push(TokenType::Mod, i); break;
            case '^': push(TokenType::Pow, i); break;
            case '!': push(TokenType::Fact, i); break;
            case '(': push(TokenType::LParen, i); break;
            case ')': push(TokenType::RParen, i); break;
        }
    }

    return tokens;
}

} // namespace wisp::calc

