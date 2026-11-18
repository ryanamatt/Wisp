// src/backend/convert/convertUnits.hpp
//
// Table driven unit conversion (length, mass, temperature, ...).

#pragma once

#include "convertCommon.hpp"
#include <string>

namespace wisp::convert {

bool isUnitName(const std::string &name);

// Converts `value` expressed in `from`. With a `to` unit the result has one
// row, with an empty `to` it lists the common units of the same category.
// Returns false for unknown units or a category mismatch.
bool runUnits(double value, const std::string &from, const std::string &to, Result &out);

} // namespace wisp::convert


