// src/backend/convert/convertColor.hpp
//
// Colour conversion between hex, rgb and hsl.

#pragma once

#include "convertCommon.hpp"
#include <string>
#include <vector>

namespace wisp::convert {

enum class ColorFormat { Hex, Rgb, Hsl };

struct Rgb {
    int r = 0;
    int g = 0;
    int b = 0;
};

bool colorFormatFromName(const std::string &name, ColorFormat &out);

// "#f0f", "ff00ff", "#ff00ff". 3 or 6 digits, no alpha.
bool looksLikeHexColor(const std::string &token);
bool parseHexColor(const std::string &token, Rgb &out, std::string &echo);

// name is "rgb" or "hsl". args is the text between the parentheses, with
// commas, spaces and % signs all accepted as separators.
bool parseColorFunction(const std::string &name, const std::string &args, Rgb &out, std::string &echo);

// `targets` is empty (list the other formats) or one format name.
bool runColor(const Rgb &c, ColorFormat source, const std::string &echo,
              const std::vector<std::string> &targets, Result &out);

} // namespace wisp::convert

