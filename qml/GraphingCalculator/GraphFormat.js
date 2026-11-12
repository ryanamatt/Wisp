// qml/GraphingCalculator/GraphFormat.js
//
// Number formatting shared by the grid labels, header and hover readout.

.pragma library

// Decimals needed to show multiples of `step` exactly (0.2 -> 1, 0.05 -> 2).
function decimalsFor(step) {
    if (!(step > 0))
        return 0;
    return Math.max(0, Math.min(10, -Math.floor(Math.log(step) / Math.LN10 + 1e-9)));
}

// Axis label for a grid line at `value`, where lines are `step` apart.
function tick(value, step) {
    if (Math.abs(value) < step * 1e-6)
        return "0";
    const mag = Math.abs(value);
    if (mag >= 1e7 || mag < 1e-5)
        return value.toExponential(2);
    return value.toFixed(decimalsFor(step));
}

// Cursor coordinate: a bit finer than the grid so it feels precise.
function coord(value, step) {
    if (!isFinite(value))
        return "undefined";
    const mag = Math.abs(value);
    if (mag >= 1e7 || (mag > 0 && mag < 1e-5))
        return value.toExponential(2);
    const text = value.toFixed(decimalsFor(step / 100));
    return Number(text) === 0 ? "0" : text;
}

// A computed y value, trimmed to about 6 significant digits.
function number(value) {
    if (!isFinite(value))
        return "undefined";
    if (value === 0)
        return "0";
    const mag = Math.abs(value);
    if (mag >= 1e6 || mag < 1e-4)
        return value.toExponential(3);
    return String(Number(value.toPrecision(6)));
}

