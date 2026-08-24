// qml/Utils/Utils.js

.pragma library

// Formats a "used / total" pair that's given in GB, automatically switching
// to TB when the total is large enough that GB gets unwieldy. Both values
// are always shown in the same unit so they stay comparable at a glance.
function formatSizePair(usedGb, totalGb) {
    if (totalGb < 0) return "-- / --"

    var unit = unitFor(totalGb)
    var used = convert(usedGb, unit)
    var total = convert(totalGb, unit)
    var decimals = unit === "TB" ? 2 : 1

    return used.toFixed(decimals) + " / " + total.toFixed(decimals) + " " + unit
}

// Formats a single GB value with automatic unit switching, e.g. for
// standalone labels rather than a used/total pair.
function formatSize(valueGb) {
    if (valueGb < 0) return "--"

    var unit = unitFor(valueGb)
    var decimals = unit === "TB" ? 2 : 1
    return convert(valueGb, unit).toFixed(decimals) + " " + unit
}

function unitFor(gbValue) {
    return gbValue >= 1024 ? "TB" : "GB"
}

function convert(gbValue, unit) {
    return unit === "TB" ? gbValue / 1024 : gbValue
}

function formatUptime(seconds) {
    if (seconds < 0) return "—"

    var totalMinutes = Math.floor(seconds / 60)
    var days = Math.floor(totalMinutes / 1440)
    var hours = Math.floor((totalMinutes % 1440) / 60)
    var minutes = totalMinutes % 60

    if (days > 0) return days + "d " + hours + "h " + minutes + "m"
    if (hours > 0) return hours + "h " + minutes + "m"
    return minutes + "m"
}

function formatLoad(value) {
    return value < 0 ? "—" : value.toFixed(2)
}
