// src/backend/convert/convertCommon.cpp

#include "convertCommon.hpp"
#include <charconv>
#include <cmath>

namespace wisp::convert {

namespace {

bool isAsciiSpace(char c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

} // namespace

std::string trim(const std::string &s) {
    size_t a = 0;
    size_t b = s.size();
    while (a < b && isAsciiSpace(s[a])) a++;
    while (b > a && isAsciiSpace(s[b - 1])) b--;
    return s.substr(a, b - a);
}

std::string toLower(std::string s) {
    for (char &c : s) {
        if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
    }
    return s;
}

std::vector<std::string> splitWhitespace(const std::string &s) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : s) {
        if (isAsciiSpace(c)) {
            if (!cur.empty()) {
                out.push_back(cur);
                cur.clear();
            }
        } else {
            cur += c;
        }
    }
    if (!cur.empty()) out.push_back(cur);
    return out;
}

bool parseDouble(const std::string &token, double &out) {
    if (token.empty()) return false;

    bool sawDigit = false;
    for (char c : token) {
        if (c >= '0' && c <= '9')
            sawDigit = true;
        else if (c != '.' && c != '+' && c != '-' && c != 'e')
            return false;
    }
    if (!sawDigit) return false;

    const char *first = token.data();
    const char *last = first + token.size();
    // from_chars does not accept a leading '+'.
    if (*first == '+') first++;
    if (first == last) return false;

    double v = 0.0;
    auto [ptr, ec] = std::from_chars(first, last, v);
    if (ec != std::errc() || ptr != last || !std::isfinite(v)) return false;

    out = v;
    return true;
}

std::string formatNumber(double v) {
    if (v == 0.0) return "0"; // also turns -0 into 0

    char buf[64];
    auto r = std::to_chars(buf, buf + sizeof(buf), v, std::chars_format::general, 12);
    std::string s(buf, r.ptr);

    // "1e+12" -> "1e12", "1e-05" -> "1e-5"
    size_t e = s.find('e');
    if (e != std::string::npos) {
        std::string mant = s.substr(0, e);
        std::string exp = s.substr(e + 1);
        bool neg = false;
        size_t i = 0;
        if (i < exp.size() && (exp[i] == '+' || exp[i] == '-')) {
            neg = exp[i] == '-';
            i++;
        }
        while (i + 1 < exp.size() && exp[i] == '0') i++;
        s = mant + "e" + (neg ? "-" : "") + exp.substr(i);
    }
    return s;
}

} // namespace wisp::convert

