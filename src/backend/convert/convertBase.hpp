// src/backend/convert/convertBase.hpp
//
// Number base conversion: bin, oct, dec, hex.

#pragma once

#include "convertCommon.hpp"
#include <string>
#include <vector>

namespace wisp::convert {

// 2, 8, 10 or 16 for "bin", "oct", "dec", "hex" (and long names), else 0.
int baseFromName(const std::string &name);

// 2, 8 or 16 when the token starts with 0b, 0o or 0x and has digits after it.
int baseFromPrefix(const std::string &token);

// `units` holds only base names: none, a target, or a source and a target.
//   "0xff"          lists the other bases
//   "0xff bin"      0xff to binary
//   "255 hex"       decimal 255 to hex (decimal is the default source)
//   "ff hex"        not valid decimal, so read as hex and list the others
//   "ff hex bin"    explicit source and target
bool runBase(const std::string &token, const std::vector<std::string> &units, Result &out);

} // namespace wisp::convert
