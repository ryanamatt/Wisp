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

// Formats a bytes/sec rate as e.g. "482 KB/s" or "1.3 MB/s".
function formatRate(bytesPerSec) {
    if (bytesPerSec < 0) return "--"
    var units = ["B/s", "KB/s", "MB/s", "GB/s"]
    var i = 0
    var val = bytesPerSec
    while (val >= 1024 && i < units.length - 1) {
        val /= 1024
        i++
    }
    var decimals = (i > 0 && val < 10) ? 1 : 0
    return val.toFixed(decimals) + " " + units[i]
}

// Formats a duration in seconds as "m:ss" or "h:mm:ss" once it reaches an hour.
// e.g. 125 -> 2:05, 7530 -. "2:05:30".
function formatTime(seconds) {
    if (!seconds || seconds < 0 || !isFinite(seconds)) return "0:00"

    var total = Math.floor(seconds)
    var hours = Math.floor(total / 3600)
    var minutes = Math.floor((total % 3600) / 60)
    var secs = total % 60

    var ss = (secs < 10 ? "0" : "") + secs
    if (hours > 0) return hours + ":" + (minutes < 10 ? "0": "") + minutes + ":" + ss
    return minutes + ":" + ss
}

