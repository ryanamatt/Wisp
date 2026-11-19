// src/backend/convert/convertUnits.cpp

#include "convertUnits.hpp"
#include <unordered_map>

namespace wisp::convert {

namespace {

constexpr double kPi = 3.14159265358979323846;

enum class Cat { Length, Mass, Temperature, Time, Volume, Area, Speed, Data, Angle, Pressure, Energy };

// A unit converts to its category's base unit with
//     base = (x + offset) * scale
// Putting the offset first keeps 32 F -> 0 C exact. Only temperature uses it.
struct Unit {
    const char *label;
    Cat cat;
    double scale;
    double offset;
    bool common;                    // Listed when no target unit is given
    std::vector<std::string> names; // Lowercase aliases, must be unique across the table
};

// To add a unit, add a line here. Nothing else needs to change.
const std::vector<Unit> &table() {
    static const std::vector<Unit> t = {
        // ---- Length, base metre ----
        {"m", Cat::Length, 1.0, 0, true, {"m", "meter", "meters", "metre", "metres"}},
        {"km", Cat::Length, 1000.0, 0, true, {"km", "kilometer", "kilometers", "kilometre", "kilometres"}},
        {"cm", Cat::Length, 0.01, 0, true, {"cm", "centimeter", "centimeters", "centimetre", "centimetres"}},
        {"mm", Cat::Length, 0.001, 0, true, {"mm", "millimeter", "millimeters", "millimetre", "millimetres"}},
        {"\xC2\xB5m", Cat::Length, 1e-6, 0, false, {"um", "\xC2\xB5m", "micron", "microns"}},
        {"nm", Cat::Length, 1e-9, 0, false, {"nm", "nanometer", "nanometers"}},
        {"mi", Cat::Length, 1609.344, 0, true, {"mi", "mile", "miles"}},
        {"yd", Cat::Length, 0.9144, 0, true, {"yd", "yds", "yard", "yards"}},
        {"ft", Cat::Length, 0.3048, 0, true, {"ft", "foot", "feet"}},
        {"in", Cat::Length, 0.0254, 0, true, {"in", "inch", "inches"}},
        {"nmi", Cat::Length, 1852.0, 0, false, {"nmi"}},

        // ---- Mass, base gram ----
        {"g", Cat::Mass, 1.0, 0, true, {"g", "gram", "grams"}},
        {"kg", Cat::Mass, 1000.0, 0, true, {"kg", "kilogram", "kilograms"}},
        {"mg", Cat::Mass, 0.001, 0, true, {"mg", "milligram", "milligrams"}},
        {"\xC2\xB5g", Cat::Mass, 1e-6, 0, false, {"ug", "\xC2\xB5g", "microgram", "micrograms"}},
        {"t", Cat::Mass, 1e6, 0, false, {"t", "tonne", "tonnes"}},
        {"lb", Cat::Mass, 453.59237, 0, true, {"lb", "lbs", "pound", "pounds"}},
        {"oz", Cat::Mass, 28.349523125, 0, true, {"oz", "ounce", "ounces"}},
        {"st", Cat::Mass, 6350.29318, 0, false, {"st", "stone"}},

        // ---- Temperature, base Celsius ----
        {"\xC2\xB0"
         "C",
         Cat::Temperature,
         1.0,
         0.0,
         true,
         {"c",
          "\xC2\xB0"
          "c",
          "celsius", "degc"}},
        {"\xC2\xB0"
         "F",
         Cat::Temperature,
         5.0 / 9.0,
         -32.0,
         true,
         {"f",
          "\xC2\xB0"
          "f",
          "fahrenheit", "degf"}},
        {"K", Cat::Temperature, 1.0, -273.15, true, {"k", "kelvin"}},

        // ---- Time, base second ----
        {"ms", Cat::Time, 0.001, 0, true, {"ms", "millisecond", "milliseconds"}},
        {"s", Cat::Time, 1.0, 0, true, {"s", "sec", "secs", "second", "seconds"}},
        {"min", Cat::Time, 60.0, 0, true, {"min", "mins", "minute", "minutes"}},
        {"h", Cat::Time, 3600.0, 0, true, {"h", "hr", "hrs", "hour", "hours"}},
        {"d", Cat::Time, 86400.0, 0, true, {"d", "day", "days"}},
        {"wk", Cat::Time, 604800.0, 0, true, {"wk", "wks", "week", "weeks"}},
        // Julian year, 365.25 days.
        {"yr", Cat::Time, 31557600.0, 0, true, {"yr", "yrs", "y", "year", "years"}},

        // ---- Volume, base litre (US customary) ----
        {"l", Cat::Volume, 1.0, 0, true, {"l", "liter", "liters", "litre", "litres"}},
        {"ml", Cat::Volume, 0.001, 0, true, {"ml", "milliliter", "milliliters", "millilitre", "millilitres"}},
        {"gal", Cat::Volume, 3.785411784, 0, true, {"gal", "gallon", "gallons"}},
        {"qt", Cat::Volume, 0.946352946, 0, true, {"qt", "quart", "quarts"}},
        {"pt", Cat::Volume, 0.473176473, 0, false, {"pt", "pint", "pints"}},
        {"cup", Cat::Volume, 0.2365882365, 0, true, {"cup", "cups"}},
        {"fl oz", Cat::Volume, 0.0295735295625, 0, true, {"floz"}},
        {"tbsp", Cat::Volume, 0.01478676478125, 0, false, {"tbsp"}},
        {"tsp", Cat::Volume, 0.00492892159375, 0, false, {"tsp"}},

        // ---- Area, base square metre ----
        {"m\xC2\xB2", Cat::Area, 1.0, 0, true, {"m2", "m\xC2\xB2", "sqm"}},
        {"km\xC2\xB2", Cat::Area, 1e6, 0, true, {"km2", "km\xC2\xB2", "sqkm"}},
        {"cm\xC2\xB2", Cat::Area, 1e-4, 0, false, {"cm2", "cm\xC2\xB2", "sqcm"}},
        {"ha", Cat::Area, 1e4, 0, true, {"ha", "hectare", "hectares"}},
        {"acre", Cat::Area, 4046.8564224, 0, true, {"acre", "acres", "ac"}},
        {"ft\xC2\xB2", Cat::Area, 0.09290304, 0, true, {"ft2", "ft\xC2\xB2", "sqft"}},
        {"in\xC2\xB2", Cat::Area, 0.00064516, 0, false, {"in2", "in\xC2\xB2", "sqin"}},
        {"yd\xC2\xB2", Cat::Area, 0.83612736, 0, false, {"yd2", "yd\xC2\xB2", "sqyd"}},
        {"mi\xC2\xB2", Cat::Area, 2589988.110336, 0, true, {"mi2", "mi\xC2\xB2", "sqmi"}},

        // ---- Speed, base metre per second ----
        {"m/s", Cat::Speed, 1.0, 0, true, {"m/s", "mps"}},
        {"km/h", Cat::Speed, 1.0 / 3.6, 0, true, {"km/h", "kph", "kmh", "kmph"}},
        {"mph", Cat::Speed, 0.44704, 0, true, {"mph", "mi/h"}},
        {"kn", Cat::Speed, 1852.0 / 3600.0, 0, true, {"kn", "kt", "kts", "knot", "knots"}},
        {"ft/s", Cat::Speed, 0.3048, 0, true, {"ft/s", "fps"}},

        // ---- Data, base byte. Lowercase input, so "kb" is kilobyte (1000). ----
        {"bit", Cat::Data, 0.125, 0, false, {"bit", "bits"}},
        {"B", Cat::Data, 1.0, 0, true, {"b", "byte", "bytes"}},
        {"KB", Cat::Data, 1e3, 0, true, {"kb", "kilobyte", "kilobytes"}},
        {"MB", Cat::Data, 1e6, 0, true, {"mb", "megabyte", "megabytes"}},
        {"GB", Cat::Data, 1e9, 0, true, {"gb", "gigabyte", "gigabytes"}},
        {"TB", Cat::Data, 1e12, 0, true, {"tb", "terabyte", "terabytes"}},
        {"PB", Cat::Data, 1e15, 0, false, {"pb", "petabyte", "petabytes"}},
        {"KiB", Cat::Data, 1024.0, 0, true, {"kib", "kibibyte", "kibibytes"}},
        {"MiB", Cat::Data, 1048576.0, 0, true, {"mib", "mebibyte", "mebibytes"}},
        {"GiB", Cat::Data, 1073741824.0, 0, true, {"gib", "gibibyte", "gibibytes"}},
        {"TiB", Cat::Data, 1099511627776.0, 0, false, {"tib", "tebibyte", "tebibytes"}},
        {"Kbit", Cat::Data, 125.0, 0, false, {"kbit", "kbits"}},
        {"Mbit", Cat::Data, 125000.0, 0, false, {"mbit", "mbits"}},
        {"Gbit", Cat::Data, 125000000.0, 0, false, {"gbit", "gbits"}},

        // ---- Angle, base degree ----
        {"\xC2\xB0", Cat::Angle, 1.0, 0, true, {"deg", "\xC2\xB0", "degree", "degrees"}},
        {"rad", Cat::Angle, 180.0 / kPi, 0, true, {"rad", "radian", "radians"}},
        {"grad", Cat::Angle, 0.9, 0, true, {"grad", "gon"}},
        {"turn", Cat::Angle, 360.0, 0, true, {"turn", "turns", "rev"}},

        // ---- Pressure, base pascal ----
        {"Pa", Cat::Pressure, 1.0, 0, true, {"pa", "pascal", "pascals"}},
        {"hPa", Cat::Pressure, 100.0, 0, false, {"hpa"}},
        {"kPa", Cat::Pressure, 1000.0, 0, true, {"kpa"}},
        {"bar", Cat::Pressure, 1e5, 0, true, {"bar"}},
        {"psi", Cat::Pressure, 6894.757293168, 0, true, {"psi"}},
        {"atm", Cat::Pressure, 101325.0, 0, true, {"atm"}},
        {"mmHg", Cat::Pressure, 133.322387415, 0, true, {"mmhg"}},
        {"Torr", Cat::Pressure, 101325.0 / 760.0, 0, false, {"torr"}},

        // ---- Energy, base joule ----
        {"J", Cat::Energy, 1.0, 0, true, {"j", "joule", "joules"}},
        {"kJ", Cat::Energy, 1000.0, 0, true, {"kj", "kilojoule", "kilojoules"}},
        {"cal", Cat::Energy, 4.184, 0, true, {"cal", "calorie", "calories"}},
        {"kcal", Cat::Energy, 4184.0, 0, true, {"kcal"}},
        {"Wh", Cat::Energy, 3600.0, 0, true, {"wh"}},
        {"kWh", Cat::Energy, 3.6e6, 0, true, {"kwh"}},
        {"BTU", Cat::Energy, 1055.05585262, 0, true, {"btu"}},
    };
    return t;
}

const std::unordered_map<std::string, const Unit *> &aliasMap() {
    static const std::unordered_map<std::string, const Unit *> m = [] {
        std::unordered_map<std::string, const Unit *> map;
        for (const Unit &u : table()) {
            for (const std::string &n : u.names) map.emplace(n, &u); // first wins
        }
        return map;
    }();
    return m;
}

const Unit *findUnit(const std::string &name) {
    auto it = aliasMap().find(name);
    return it == aliasMap().end() ? nullptr : it->second;
}

double toBase(const Unit &u, double x) {
    return (x + u.offset) * u.scale;
}

double fromBase(const Unit &u, double b) {
    return b / u.scale - u.offset;
}

Row makeRow(const Unit &u, double base) {
    std::string v = formatNumber(fromBase(u, base));
    return Row{u.label, v, v + " " + u.label};
}

} // namespace

bool isUnitName(const std::string &name) {
    return findUnit(name) != nullptr;
}

bool runUnits(double value, const std::string &from, const std::string &to, Result &out) {
    const Unit *f = findUnit(from);
    if (!f) return false;

    const double base = toBase(*f, value);
    std::vector<Row> rows;

    if (!to.empty()) {
        const Unit *t = findUnit(to);
        if (!t || t->cat != f->cat) return false;
        rows.push_back(makeRow(*t, base));
    } else {
        for (const Unit &u : table()) {
            if (u.cat == f->cat && u.common && &u != f) rows.push_back(makeRow(u, base));
        }
    }
    if (rows.empty()) return false;

    out.ok = true;
    out.input = formatNumber(value) + " " + f->label;
    out.rows = std::move(rows);
    return true;
}

} // namespace wisp::convert
