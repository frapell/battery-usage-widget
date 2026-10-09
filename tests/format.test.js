// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

const assert = require("assert/strict");
const F = require("./load")("format.js");

const base = { decimals: 1, timeFormat: 0, locale: null };
const opt = (o) => Object.assign({}, base, o);
const MIN = 60000, H = 60 * MIN;

// formatWatts
assert.equal(F.formatWatts(9.84, base), "9.8 W");
assert.equal(F.formatWatts(9.84, opt({ decimals: 0 })), "10 W");
assert.equal(F.formatWatts(9.845, opt({ decimals: 2 })), "9.85 W");
assert.equal(F.formatWatts(-3, base), "0.0 W");
assert.equal(F.formatWatts(undefined, base), "0.0 W");
assert.equal(F.formatWatts(NaN, base), "0.0 W");

// formatEnergy
assert.equal(F.formatEnergy(38.24, null), "38.2 Wh");
assert.equal(F.formatEnergy(undefined, null), "0.0 Wh");

// formatDuration
assert.equal(F.formatDuration(0, 0, null), "—");
assert.equal(F.formatDuration(NaN, 0, null), "—");
assert.equal(F.formatDuration(-1, 0, null), "—");
assert.equal(F.formatDuration(2 * H + 45 * MIN, 0, null), "2:45");
assert.equal(F.formatDuration(7 * MIN, 0, null), "0:07");
assert.equal(F.formatDuration(2 * H + 59 * MIN + 36000, 0, null), "3:00", "rounds to whole minutes first");
assert.equal(F.formatDuration(26 * H + 5 * MIN, 0, null), "26:05");
assert.equal(F.formatDuration(2 * H + 45 * MIN, 1, null), "2h 45m");
assert.equal(F.formatDuration(45 * MIN, 1, null), "45m");
assert.equal(F.formatDuration(3 * H, 1, null), "3h");
assert.equal(F.formatDuration(2 * H + 45 * MIN, 2, null), "2.8 h");
assert.equal(F.formatDuration(2 * H + 45 * MIN, 3, null), "");
assert.equal(F.formatDuration(0, 3, null), "", "hidden even when unknown");
console.log("duration: ok");

// compactText
assert.equal(F.compactText(9.8, 2 * H + 45 * MIN, base), "9.8 W · 2:45");
assert.equal(F.compactText(9.8, 0, base), "9.8 W · —");
assert.equal(F.compactText(9.8, 2 * H + 45 * MIN, opt({ timeFormat: 3 })), "9.8 W");
assert.equal(F.compactText(9.8, 2 * H + 45 * MIN, opt({ separator: "\n" })), "9.8 W\n2:45");
assert.equal(F.compactText(0, 2 * H, base), "—", "estimating");
assert.equal(F.compactText(undefined, 0, base), "—");
console.log("compact: ok");

// widestTexts covers what compactText produces for anything that rounds
// below 100 W, and times under 100 h
assert.deepEqual(Array.from(F.widestTexts(base)), ["99.9 W · 99:59", "—"]);
assert.deepEqual(Array.from(F.widestTexts(opt({ decimals: 0, timeFormat: 3, separator: "\n" }))), ["99 W", "—"]);
for (const fmt of [0, 1, 2, 3]) {
    for (const decimals of [0, 1, 2]) {
        for (const separator of [undefined, "\n"]) {
            const o = opt({ timeFormat: fmt, decimals: decimals, separator: separator });
            const widest = (s) => Math.max(...s.split("\n").map((l) => l.length));
            const reserved = Math.max(...F.widestTexts(o).map(widest));
            for (let w = 0; w < 100 - 0.5 * Math.pow(10, -decimals); w += 0.37) {
                for (let ms = 0; ms < 99 * H; ms += 17 * MIN + 3000) {
                    const t = F.compactText(w, ms, o);
                    assert.ok(widest(t) <= reserved, `${JSON.stringify(t)} wider than reserved`);
                }
            }
        }
    }
}
console.log("format: ok");
