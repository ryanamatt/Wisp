// qml/Runner/SymbolIndex.js
//
// Builds the symbol list for RunnerSymbolPopup from files the system already has.

.pragma library

// Blocks taken from UnicodeData.txt. The file is sorted by code point, so
// parsing stops after UCD_LAST.
var UCD_RANGES = [
    [0x00A1, 0x00FF], // Latin-1 symbols and letters
    [0x0370, 0x03FF], // Greek
    [0x2010, 0x205E], // General punctuation
    [0x2070, 0x209F], // Super and subscripts
    [0x20A0, 0x20CF], // Currency
    [0x2100, 0x214F], // Letterlike symbols
    [0x2150, 0x218F], // Number forms (fractions)
    [0x2190, 0x21FF], // Arrows
    [0x2200, 0x22FF], // Math operators
    [0x2300, 0x23FF], // Technical
    [0x2460, 0x27FF], // Enclosed numbers, box drawing, shapes, dingbats
    [0x2B00, 0x2BFF]  // More symbols and arrows
];
var UCD_LAST = 0x2BFF;

// General categories that do not make a useful grid cell.
var UCD_SKIP = { Mn: 1, Mc: 1, Me: 1, Cc: 1, Cf: 1, Cs: 1, Co: 1, Cn: 1, Zs: 1, Zl: 1, Zp: 1 };

function decodeEntities(s) {
    return s.replace(/&quot;/g, '"').replace(/&apos;/g, "'")
            .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");
}

function makeEntry(glyph, name, keywords) {
    return {
        c: glyph,
        n: name,
        lname: name.toLowerCase(),
        hay: (name + " " + keywords + " " + glyph).toLowerCase()
    };
}

function inUcdRanges(code) {
    for (var i = 0; i < UCD_RANGES.length; i++) {
        if (code >= UCD_RANGES[i][0] && code <= UCD_RANGES[i][1]) return true;
    }
    return false;
}

// CLDR annotations. Returns { emoji: [], other: [] }.
function parseCldr(text) {
    var byCp = {};
    var list = [];
    var re = /<annotation\s+([^>]*)>([^<]*)<\/annotation>/g;
    var m;

    while ((m = re.exec(text)) !== null) {
        var cpMatch = /cp="([^"]*)"/.exec(m[1]);
        if (!cpMatch) continue;
        var cp = decodeEntities(cpMatch[1]);

        // Blank cells and the bare skin tone swatches are not useful.
        if (/^\s*$/.test(cp)) continue;
        var first = cp.codePointAt(0);
        if (first >= 0x1F3FB && first <= 0x1F3FF && cp.length <= 2) continue;

        var e = byCp[cp];
        if (!e) {
            e = byCp[cp] = { cp: cp, name: "", kw: "" };
            list.push(e);
        }
        if (m[1].indexOf('type="tts"') !== -1)
            e.name = decodeEntities(m[2]);
        else
            e.kw = decodeEntities(m[2]).replace(/\s*\|\s*/g, " ");
    }

    var start = -1;
    var end = -1;
    var firstAstral = -1;
    for (var i = 0; i < list.length; i++) {
        if (list[i].cp === "\u{1F600}") start = i;
        if (list[i].cp.codePointAt(0) >= 0x1F000) {
            if (firstAstral < 0) firstAstral = i;
            end = i;
        }
    }
    if (start < 0) start = firstAstral;

    var emoji = [];
    var lateEmoji = [];
    var other = [];
    for (var j = 0; j < list.length; j++) {
        var it = list[j];
        var name = it.name || it.kw.split(" ")[0] || it.cp;
        var glyph = it.cp;
        var isEmoji = start >= 0 && j >= start && j <= end;

        // CLDR omits the emoji presentation selector. Without it, glyphs like
        // the red heart paste as flat text symbols in some apps.
        if (isEmoji && glyph.length === 1) {
            var code = glyph.charCodeAt(0);
            if (code >= 0x2190 && code <= 0x2BFF) glyph += "\uFE0F";
        }

        var entry = makeEntry(glyph, name, it.kw);
        entry.base = it.cp;

        if (isEmoji) emoji.push(entry);
        else if (it.cp.codePointAt(0) >= 0x1F000) lateEmoji.push(entry);
        else other.push(entry);
    }

    return { emoji: emoji.concat(lateEmoji), other: other };
}

// Named characters from UnicodeData.txt that are not already present.
function parseUcd(text, seen) {
    var out = [];
    var pos = 0;
    var len = text.length;

    while (pos < len) {
        var nl = text.indexOf("\n", pos);
        if (nl < 0) nl = len;

        var semi = text.indexOf(";", pos);
        if (semi < 0 || semi > nl) {
            pos = nl + 1;
            continue;
        }

        var code = parseInt(text.substring(pos, semi), 16);
        if (code > UCD_LAST) break;

        if (inUcdRanges(code)) {
            var f = text.substring(pos, nl).split(";");
            if (f[1].charAt(0) !== "<" && !UCD_SKIP[f[2]]) {
                var glyph = String.fromCodePoint(code);
                var uname = f[1].toLowerCase();
                // Unicode spells it "lamda", but everyone searches "lambda".
                var alias = uname.indexOf("lamda") !== -1 ? "lambda" : "";
                if (!seen[glyph]) out.push(makeEntry(glyph, uname, alias));
            }
        }
        pos = nl + 1;
    }

    return out;
}

// Either text may be empty when that file is missing.
function build(cldrText, ucdText) {
    var cldr = parseCldr(cldrText || "");
    var all = cldr.emoji.concat(cldr.other);

    var seen = {};
    for (var i = 0; i < all.length; i++) seen[all[i].base] = true;

    return all.concat(parseUcd(ucdText || "", seen));
}

// Every word in the query must match somewhere. Names that start with a word
// rank above partial matches, which rank above keyword-only matches.
function search(entries, query) {
    var tokens = String(query).toLowerCase().split(/\s+/).filter(function (t) {
        return t.length > 0;
    });
    if (tokens.length === 0) return entries;

    var scored = [];
    for (var i = 0; i < entries.length; i++) {
        var e = entries[i];
        var score = 0;
        var ok = true;

        for (var t = 0; t < tokens.length; t++) {
            var tok = tokens[t];
            if (e.lname.indexOf(tok) === 0) score += 0;
            else if (e.lname.indexOf(" " + tok) !== -1) score += 1;
            else if (e.hay.indexOf(tok) !== -1) score += 2;
            else { ok = false; break; }
        }

        if (ok) scored.push({ e: e, s: score, i: i });
    }

    scored.sort(function (a, b) { return (a.s - b.s) || (a.i - b.i); });
    return scored.map(function (x) { return x.e; });
}
