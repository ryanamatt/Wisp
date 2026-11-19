// src/backend/convert/convertBase.cpp

#include "convertBase.hpp"
#include <cstdint>

namespace wisp::convert {

namespace {

const char *baseLabel(int base) {
    switch (base) {
        case 2: return "bin";
        case 8: return "oct";
        case 10: return "dec";
        default: return "hex";
    }
}

const char *basePrefix(int base) {
    switch (base) {
        case 2: return "0b";
        case 8: return "0o";
        case 16: return "0x";
        default: return "";
    }
}

// Digits only, underscores allowed as separators. False on bad digits or
// overflow past 64 bits.
bool parseDigits(const std::string &text, int base, uint64_t &out) {
    uint64_t v = 0;
    bool any = false;

    for (char c : text) {
        if (c == '_') continue;

        int d;
        if (c >= '0' && c <= '9')
            d = c - '0';
        else if (c >= 'a' && c <= 'f')
            d = c - 'a' + 10;
        else
            return false;

        if (d >= base) return false;
        if (v > (UINT64_MAX - static_cast<uint64_t>(d)) / static_cast<uint64_t>(base)) return false;

        v = v * static_cast<uint64_t>(base) + static_cast<uint64_t>(d);
        any = true;
    }

    if (!any) return false;
    out = v;
    return true;
}

std::string digitsOf(uint64_t v, int base) {
    if (v == 0) return "0";
    std::string s;
    while (v > 0) {
        s.insert(s.begin(), "0123456789abcdef"[v % static_cast<uint64_t>(base)]);
        v /= static_cast<uint64_t>(base);
    }
    return s;
}

// "11111111" -> "1111 1111"
std::string groupNibbles(const std::string &bits) {
    std::string out;
    const size_t n = bits.size();
    for (size_t i = 0; i < n; i++) {
        if (i > 0 && (n - i) % 4 == 0) out += ' ';
        out += bits[i];
    }
    return out;
}

Row makeRow(uint64_t v, int base) {
    const std::string digits = digitsOf(v, base);
    const std::string prefix = basePrefix(base);
    const std::string shown = (base == 2) ? groupNibbles(digits) : digits;
    return Row{baseLabel(base), prefix + shown, prefix + digits};
}

} // namespace

int baseFromName(const std::string &name) {
    if (name == "bin" || name == "binary") return 2;
    if (name == "oct" || name == "octal") return 8;
    if (name == "dec" || name == "decimal") return 10;
    if (name == "hex" || name == "hexadecimal") return 16;
    return 0;
}

int baseFromPrefix(const std::string &token) {
    if (token.size() <= 2 || token[0] != '0') return 0;
    switch (token[1]) {
        case 'x': return 16;
        case 'b': return 2;
        case 'o': return 8;
        default: return 0;
    }
}

bool runBase(const std::string &token, const std::vector<std::string> &units, Result &out) {
    if (units.size() > 2) return false;

    std::vector<int> bases;
    for (const std::string &u : units) {
        int b = baseFromName(u);
        if (b == 0) return false;
        bases.push_back(b);
    }

    const int prefixBase = baseFromPrefix(token);
    int from = 0;
    int to = 0;
    std::string digits = token;
    std::string echo = token;
    uint64_t value = 0;

    if (bases.size() == 2) {
        // Explicit source. Only strip a prefix that agrees with it.
        from = bases[0];
        to = bases[1];
        if (prefixBase == from) digits = token.substr(2);
        if (!parseDigits(digits, from, value)) return false;
        echo = token + " " + baseLabel(from);

    } else if (prefixBase != 0) {
        from = prefixBase;
        if (bases.size() == 1) to = bases[0];
        if (!parseDigits(token.substr(2), from, value)) return false;

    } else if (bases.size() == 1) {
        if (parseDigits(token, 10, value)) {
            from = 10;
            to = bases[0];
            echo = token + " dec";
        } else if (parseDigits(token, bases[0], value)) {
            from = bases[0];
            echo = token + " " + baseLabel(from);
        } else {
            return false;
        }

    } else {
        return false;
    }

    std::vector<Row> rows;
    if (to != 0) {
        rows.push_back(makeRow(value, to));
    } else {
        for (int b : {2, 8, 10, 16}) {
            if (b != from) rows.push_back(makeRow(value, b));
        }
    }

    out.ok = true;
    out.input = echo;
    out.rows = std::move(rows);
    return true;
}

} // namespace wisp::convert
