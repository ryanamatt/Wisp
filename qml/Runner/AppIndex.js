// qml/Runner/AppIndex.js
//
// Turns Quickshell DesktopEntry objects into searchable entries, and ranks
// them against a query using name matches first and launch history second.

.pragma library

function joinList(list) {
    if (!list) return "";
    return Array.prototype.join.call(list, " ");
}

// "Visual Studio Code" -> "vsc"
function initialsOf(name) {
    var parts = name.toLowerCase().split(/[\s\-_.]+/);
    var out = "";
    for (var i = 0; i < parts.length; i++) {
        if (parts[i].length > 0) out += parts[i].charAt(0);
    }
    return out;
}

function basename(path) {
    var i = path.lastIndexOf("/");
    return i >= 0 ? path.substring(i + 1) : path;
}

// apps: DesktopEntries.applications.values
function build(apps) {
    var out = [];
    var seen = {};

    for (var i = 0; i < apps.length; i++) {
        var a = apps[i];
        if (a.noDisplay) continue;

        var name = a.name || a.id;
        if (!name || seen[a.id]) continue;
        seen[a.id] = true;

        var generic = a.genericName || "";
        var comment = a.comment || "";
        var bin = (a.command && a.command.length > 0) ? basename(String(a.command[0])) : "";

        out.push({
            id: a.id,
            entry: a,
            name: name,
            lname: name.toLowerCase(),
            initials: initialsOf(name),
            detail: comment || generic,
            icon: a.icon || "",
            // Everything that is searchable but is not the name.
            extra: (generic + " " + comment + " " + joinList(a.keywords) + " "
                    + joinList(a.categories) + " " + bin + " " + a.id).toLowerCase()
        });
    }

    out.sort(function (x, y) {
        return x.lname < y.lname ? -1 : (x.lname > y.lname ? 1 : 0);
    });
    return out;
}

// usage entry: { c: launch count, t: last launch time in ms }.
// The count halves every two weeks, so old favourites fade out.
function frecency(u, now) {
    if (!u) return 0;
    var days = Math.max(0, (now - u.t) / 86400000);
    return u.c * Math.pow(0.5, days / 14);
}

function isSubsequence(needle, hay) {
    var j = 0;
    for (var i = 0; i < hay.length && j < needle.length; i++) {
        if (hay.charAt(i) === needle.charAt(j)) j++;
    }
    return j === needle.length;
}

// Lower is better, -1 means no match.
function matchToken(e, tok) {
    if (e.lname.indexOf(tok) === 0) return 0;
    if (e.lname.indexOf(" " + tok) !== -1) return 1;
    if (tok.length >= 2 && e.initials.indexOf(tok) === 0) return 1.5;
    if (e.lname.indexOf(tok) !== -1) return 2;
    if (tok.length >= 2 && e.extra.indexOf(tok) !== -1) return 3;
    if (tok.length >= 3 && isSubsequence(tok, e.lname)) return 4;
    return -1;
}

// Every word in the query must match. Better matches rank first, and
// frecency breaks ties. With an empty query, used apps come first.
function search(entries, query, usage, now) {
    var tokens = String(query).toLowerCase().split(/\s+/).filter(function (t) {
        return t.length > 0;
    });

    var scored = [];
    for (var i = 0; i < entries.length; i++) {
        var e = entries[i];
        var score = 0;
        var ok = true;

        for (var t = 0; t < tokens.length; t++) {
            var s = matchToken(e, tokens[t]);
            if (s < 0) { ok = false; break; }
            score += s;
        }

        if (ok) scored.push({ e: e, s: score, f: frecency(usage[e.id], now), i: i });
    }

    scored.sort(function (a, b) {
        return (a.s - b.s) || (b.f - a.f) || (a.i - b.i);
    });
    return scored.map(function (x) { return x.e; });
}
