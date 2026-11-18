// src/backend/convert/convertCore.cpp
//
// A query is "<value> [from] [to]". The unit words decide what kind of
// conversion it is, and the kind decides how the value is read. That is how
// "100 f c" (temperature) and "ff00ff rgb" (colour) never get confused even
// though f, c and ff00ff are all valid hex digits.

#include "convertCore.hpp"
#include "convertBase.hpp"
#include "convertColor.hpp"
#include "convertUnits.hpp"
#include <algorithm>

namespace wisp::convert {

namespace {

bool startsWith(const std::string &s, const std::string &prefix) {
    return s.compare(0, prefix.size(), prefix) == 0;
}

// "to" is filler: "5 km to mi" is the same as "5 km mi".
std::vector<std::string> dropFiller(std::vector<std::string> tokens) {
    tokens.erase(std::remove(tokens.begin(), tokens.end(), std::string("to")), tokens.end());
    return tokens;
}

// Length of the leading number in "5km" or "1e3kg", or 0 when there is none.
size_t numberPrefixLength(const std::string &s) {
    size_t i = 0;
    if (i < s.size() && (s[i] == '+' || s[i] == '-')) i++;

    bool digits = false;
    bool dot = false;
    while (i < s.size()) {
        if (s[i] >= '0' && s[i] <= '9') {
            digits = true;
        } else if (s[i] == '.' && !dot) {
            dot = true;
        } else {
            break;
        }
        i++;
    }
    if (!digits) return 0;

    // An exponent only counts when digits follow it, so "5em" stays "5" + "em".
    if (i < s.size() && s[i] == 'e') {
        size_t j = i + 1;
        if (j < s.size() && (s[j] == '+' || s[j] == '-')) j++;
        if (j < s.size() && s[j] >= '0' && s[j] <= '9') {
            while (j < s.size() && s[j] >= '0' && s[j] <= '9') j++;
            i = j;
        }
    }
    return i;
}

// "5km" -> value "5", unit "km" in front of the other units. Only splits when
// the suffix really is a unit, so "00ff00" is left alone.
void splitGluedUnit(std::string &value, std::vector<std::string> &units) {
    double ignored;
    if (baseFromPrefix(value) != 0 || parseDouble(value, ignored)) return;

    const size_t n = numberPrefixLength(value);
    if (n == 0 || n >= value.size()) return;

    const std::string suffix = value.substr(n);
    if (isUnitName(suffix) || baseFromName(suffix) != 0) {
        value = value.substr(0, n);
        units.insert(units.begin(), suffix);
    }
}

bool isColorOnlyFormat(const std::string &name) {
    return name == "rgb" || name == "hsl";
}

} // namespace

Result run(const std::string &query) {
    Result res;

    const std::string q = toLower(trim(query));
    if (q.empty()) return res;

    // ---- Colour functions: rgb(...) and hsl(...) ----
    // These contain spaces and commas, so they are handled before tokenizing.
    for (const char *fn : {"rgb", "hsl"}) {
        const std::string head = std::string(fn) + "(";
        if (!startsWith(q, head)) continue;

        // A missing ')' is fine, so a colour previews while it is typed.
        const size_t close = q.find(')');
        const std::string args = (close == std::string::npos)
            ? q.substr(head.size())
            : q.substr(head.size(), close - head.size());
        const std::string rest = (close == std::string::npos) ? "" : q.substr(close + 1);

        Rgb c;
        std::string echo;
        if (!parseColorFunction(fn, args, c, echo)) return res;

        const ColorFormat source = std::string(fn) == "rgb" ? ColorFormat::Rgb : ColorFormat::Hsl;
        runColor(c, source, echo, dropFiller(splitWhitespace(rest)), res);
        return res;
    }

    std::vector<std::string> tokens = splitWhitespace(q);
    if (tokens.empty()) return res;

    std::string value = tokens[0];
    std::vector<std::string> units = dropFiller(std::vector<std::string>(tokens.begin() + 1, tokens.end()));

    // ---- Colour: "#ff00ff", or a bare hex value with rgb/hsl as the unit ----
    const bool colorUnit = std::any_of(units.begin(), units.end(), isColorOnlyFormat);
    if (looksLikeHexColor(value) && (value[0] == '#' || colorUnit)) {
        Rgb c;
        std::string echo;
        if (!parseHexColor(value, c, echo)) return res;

        // "ff00ff hex rgb": the leading "hex" just names the source.
        if (units.size() == 2 && units[0] == "hex") units.erase(units.begin());

        runColor(c, ColorFormat::Hex, echo, units, res);
        return res;
    }

    // ---- "5km" -> "5 km" ----
    splitGluedUnit(value, units);

    // ---- Number bases ----
    const bool baseUnit = std::any_of(units.begin(), units.end(),
                                      [](const std::string &u) { return baseFromName(u) != 0; });
    if (baseFromPrefix(value) != 0 || baseUnit) {
        runBase(value, units, res);
        return res;
    }

    // ---- Everything else is a unit conversion ----
    double v;
    if (!parseDouble(value, v)) return res;

    if (units.size() == 1)
        runUnits(v, units[0], "", res);
    else if (units.size() == 2)
        runUnits(v, units[0], units[1], res);

    return res;
}

} // namespace wisp::convert
