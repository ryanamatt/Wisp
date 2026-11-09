// src/backend/calculator/calcFunctions.cpp

#include "calcFunctions.hpp"
#include <cmath>
#include <limits>

namespace wisp::calc {

namespace {

constexpr double kNaN = std::numeric_limits<double>::quiet_NaN();

double fSqrt(double v) {
    return v < 0.0 ? kNaN : std::sqrt(v);
}
double fSin(double v) {
    return std::sin(v);
}
double fCos(double v) {
    return std::cos(v);
}
double fTan(double v) {
    return std::tan(v);
}
double fAsin(double v) {
    return std::asin(v);
}
double fAcos(double v) {
    return std::acos(v);
}
double fAtan(double v) {
    return std::atan(v);
}
double fCsc(double v) {
    return 1.0 / std::sin(v);
}
double fSec(double v) {
    return 1.0 / std::cos(v);
}
double fCot(double v) {
    return 1.0 / std::tan(v);
}
double fLn(double v) {
    return v <= 0.0 ? kNaN : std::log(v);
}
double fLog10(double v) {
    return v <= 0.0 ? kNaN : std::log10(v);
}
double fAbs(double v) {
    return std::fabs(v);
}
double fExp(double v) {
    return std::exp(v);
}

const FunctionInfo kFunctions[] = {
    {"sqrt", fSqrt}, {"sin", fSin},     {"cos", fCos},   {"tan", fTan}, {"asin", fAsin},
    {"acos", fAcos}, {"atan", fAtan},   {"csc", fCsc},   {"sec", fSec}, {"cot", fCot},
    {"ln", fLn},     {"log10", fLog10}, {"log", fLog10}, {"abs", fAbs}, {"exp", fExp},
};

} // namespace

int functionCount() {
    return (int)(sizeof(kFunctions) / sizeof(kFunctions[0]));
}

const FunctionInfo &functionAt(int index) {
    return kFunctions[index];
}

int findFunction(std::string_view name) {
    for (int i = 0; i < functionCount(); i++) {
        if (kFunctions[i].name == name) return i;
    }
    return -1;
}

} // namespace wisp::calc
