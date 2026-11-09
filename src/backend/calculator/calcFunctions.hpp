// src/backend/calculator/calcFunctions.hpp
//
// Table of named one-argument functions (sin, sqrt, ln, ...).

#pragma once

#include <string_view>

namespace wisp::calc {

using UnaryFn = double (*)(double);

struct FunctionInfo {
    std::string_view name;
    UnaryFn fn;
};

// Number of entries in the table.
int functionCount();

// Entry by index (0 <= index < functionCount()).
const FunctionInfo &functionAt(int index);

// Index of the function with this exact (lowercase) name, or -1.
int findFunction(std::string_view name);

} // namespace wisp::calc
