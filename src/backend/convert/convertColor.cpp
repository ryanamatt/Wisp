// src/backend/convert/convertColor.cpp

#include "convertColor.hpp"
#include <algorithm>
#include <cmath>
#include <cstdio>

namespace wisp::convert {

namespace {

bool isHexDigit(char c) {
    return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f');
}

int hexValue(char c) {
    return (c >= '0' && c <= '9') ? c - '0' : c - 'a' + 10;
}

struct Hsl {
    int h = 0;
    int s = 0;
    int l = 0;
};

Hsl toHsl(const Rgb &c) {
    const double r = c.r / 255.0;
    const double g = c.g / 255.0;
    const double b = c.b / 255.0;
    const double mx = std::max({r, g, b});
    const double mn = std::min({r, g, b});
    const double l = (mx + mn) / 2.0;

    double h = 0.0;
    double s = 0.0;
    if (mx != mn) {
        const double d = mx - mn;
        s = l > 0.5 ? d / (2.0 - mx - mn) : d / (mx + mn);
        if (mx == r)
            h = (g - b) / d + (g < b ? 6.0 : 0.0);
        else if (mx == g)
            h = (b - r) / d + 2.0;
        else
            h = (r - g) / d + 4.0;
        h *= 60.0;
    }

    Hsl out;
    out.h = static_cast<int>(std::lround(h)) % 360;
    out.s = static_cast<int>(std::lround(s * 100.0));
    out.l = static_cast<int>(std::lround(l * 100.0));
    return out;
}

Rgb fromHsl(double h, double s, double l) {
    s /= 100.0;
    l /= 100.0;
    h = std::fmod(h, 360.0);
    if (h < 0.0) h += 360.0;

    const double c = (1.0 - std::fabs(2.0 * l - 1.0)) * s;
    const double x = c * (1.0 - std::fabs(std::fmod(h / 60.0, 2.0) - 1.0));
    const double m = l - c / 2.0;

    double r = 0.0;
    double g = 0.0;
    double b = 0.0;
    switch (static_cast<int>(h / 60.0)) {
        case 0:
            r = c;
            g = x;
            break;
        case 1:
            r = x;
            g = c;
            break;
        case 2:
            g = c;
            b = x;
            break;
        case 3:
            g = x;
            b = c;
            break;
        case 4:
            r = x;
            b = c;
            break;
        default:
            r = c;
            b = x;
            break;
    }

    Rgb out;
    out.r = static_cast<int>(std::lround((r + m) * 255.0));
    out.g = static_cast<int>(std::lround((g + m) * 255.0));
    out.b = static_cast<int>(std::lround((b + m) * 255.0));
    return out;
}

std::string formatHex(const Rgb &c) {
    char buf[16];
    std::snprintf(buf, sizeof(buf), "#%02x%02x%02x", c.r, c.g, c.b);
    return buf;
}

std::string formatRgb(const Rgb &c) {
    return "rgb(" + std::to_string(c.r) + ", " + std::to_string(c.g) + ", " + std::to_string(c.b) + ")";
}

std::string formatHsl(const Rgb &c) {
    const Hsl h = toHsl(c);
    return "hsl(" + std::to_string(h.h) + ", " + std::to_string(h.s) + "%, " + std::to_string(h.l) + "%)";
}

Row makeRow(const Rgb &c, ColorFormat f) {
    // Colour rows carry no label, the value already says which format it is.
    std::string text;
    switch (f) {
        case ColorFormat::Hex: text = formatHex(c); break;
        case ColorFormat::Rgb: text = formatRgb(c); break;
        case ColorFormat::Hsl: text = formatHsl(c); break;
    }
    return Row{"", text, text};
}

} // namespace

bool colorFormatFromName(const std::string &name, ColorFormat &out) {
    if (name == "hex")
        out = ColorFormat::Hex;
    else if (name == "rgb")
        out = ColorFormat::Rgb;
    else if (name == "hsl")
        out = ColorFormat::Hsl;
    else
        return false;
    return true;
}

bool looksLikeHexColor(const std::string &token) {
    const size_t start = (!token.empty() && token[0] == '#') ? 1 : 0;
    const size_t n = token.size() - start;
    if (n != 3 && n != 6) return false;
    for (size_t i = start; i < token.size(); i++) {
        if (!isHexDigit(token[i])) return false;
    }
    return true;
}

bool parseHexColor(const std::string &token, Rgb &out, std::string &echo) {
    if (!looksLikeHexColor(token)) return false;

    const std::string d = token[0] == '#' ? token.substr(1) : token;
    if (d.size() == 3) {
        out.r = hexValue(d[0]) * 17;
        out.g = hexValue(d[1]) * 17;
        out.b = hexValue(d[2]) * 17;
    } else {
        out.r = hexValue(d[0]) * 16 + hexValue(d[1]);
        out.g = hexValue(d[2]) * 16 + hexValue(d[3]);
        out.b = hexValue(d[4]) * 16 + hexValue(d[5]);
    }
    echo = "#" + d;
    return true;
}

bool parseColorFunction(const std::string &name, const std::string &args, Rgb &out, std::string &echo) {
    std::string cleaned = args;
    for (char &c : cleaned) {
        if (c == ',' || c == '/' || c == '%') c = ' ';
    }

    const std::vector<std::string> parts = splitWhitespace(cleaned);
    if (parts.size() != 3) return false;

    double v[3];
    for (int i = 0; i < 3; i++) {
        if (!parseDouble(parts[i], v[i])) return false;
    }

    if (name == "rgb") {
        for (double x : v) {
            if (x < 0.0 || x > 255.0) return false;
        }
        out.r = static_cast<int>(std::lround(v[0]));
        out.g = static_cast<int>(std::lround(v[1]));
        out.b = static_cast<int>(std::lround(v[2]));
        echo = formatRgb(out);
        return true;
    }

    if (name == "hsl") {
        if (v[1] < 0.0 || v[1] > 100.0 || v[2] < 0.0 || v[2] > 100.0) return false;
        out = fromHsl(v[0], v[1], v[2]);
        echo = "hsl(" + formatNumber(v[0]) + ", " + formatNumber(v[1]) + "%, " + formatNumber(v[2]) + "%)";
        return true;
    }

    return false;
}

bool runColor(const Rgb &c, ColorFormat source, const std::string &echo, const std::vector<std::string> &targets,
              Result &out) {
    std::vector<Row> rows;

    if (targets.size() == 1) {
        ColorFormat f;
        if (!colorFormatFromName(targets[0], f)) return false;
        rows.push_back(makeRow(c, f));
    } else if (targets.empty()) {
        for (ColorFormat f : {ColorFormat::Hex, ColorFormat::Rgb, ColorFormat::Hsl}) {
            if (f != source) rows.push_back(makeRow(c, f));
        }
    } else {
        return false;
    }

    out.ok = true;
    out.input = echo;
    out.swatch = formatHex(c);
    out.rows = std::move(rows);
    return true;
}

} // namespace wisp::convert
