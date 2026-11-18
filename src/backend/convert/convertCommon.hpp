// src/backend/convert/convertCommon.hpp
//
// Shared types and helpers for the converter core. Plain C++, no Qt, so the
// whole core can be compiled and tested without a QML engine.

#pragma once

#include <string>
#include <vector>

namespace wisp::convert {

// One line in the popup.
struct Row {
    std::string label; // Unit or format name, may be empty ("km", "bin")
    std::string value; // Text shown for the row ("3.10686", "0b1111 1111")
    std::string copy;  // Text put on the clipboard
};

struct Result {
    bool ok = false;
    std::string input;  // The input repeated back ("5 km")
    std::string swatch; // "#rrggbb" for colour results, otherwise empty
    std::vector<Row> rows;
};

std::string trim(const std::string &s);
std::string toLower(std::string s); // ASCII only, UTF-8 bytes pass through
std::vector<std::string> splitWhitespace(const std::string &s);

// Strict number parse: digits, '.', sign and exponent only. Rejects "inf",
// "nan", hex floats and trailing junk. Locale independent.
bool parseDouble(const std::string &token, double &out);

// 12 significant digits, so 0.1 + 0.2 style noise disappears.
std::string formatNumber(double v);

} // namespace wisp::convert
