// src/backend/convert/convertCore.hpp
//
// Entry point of the converter. Decides which kind of conversion a query is
// and hands it to the right engine.

#pragma once

#include "convertCommon.hpp"
#include <string>

namespace wisp::convert {

// `query` is the text after the Runner's "~". Never throws. result.ok is
// false when the query is not (yet) a valid conversion.
Result run(const std::string &query);

} // namespace wisp::convert

