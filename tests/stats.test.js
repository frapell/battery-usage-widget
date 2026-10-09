// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

const assert = require("assert/strict");
const S = require("./load")("stats.js");

// band
assert.equal(S.band(5.99, 6, 12), 0);
assert.equal(S.band(6, 6, 12), 1);
assert.equal(S.band(12, 6, 12), 1);
assert.equal(S.band(12.01, 6, 12), 2);
assert.equal(S.band(0, 6, 12), 0);

// barMax
assert.equal(S.barMax(true, 12, 20), 18);
assert.equal(S.barMax(false, 12, 20), 20);
assert.equal(S.barMax(false, 12, 0), 1, "never below 1 W");
assert.equal(S.barMax(true, 0.2, 20), 1);
console.log("band: ok");

// session, times in ms
let s = S.begin();
assert.equal(S.average(s, 1000), 0, "empty");
assert.equal(s.peak, 0);
S.add(s, 0, 10);
assert.equal(S.average(s, 0), 10, "zero span is the last rate");
S.add(s, 30000, 20);
assert.equal(S.average(s, 60000), 15, "time-weighted");
assert.equal(s.peak, 20);

s = S.begin();
S.add(s, 0, 10);
S.add(s, 90000, 30);
assert.equal(S.average(s, 100000), 12);

s = S.begin();
S.add(s, 0, 0);
S.add(s, 5000, -4);
S.add(s, 10000, NaN);
assert.equal(s.count, 0, "non-positive samples are ignored");
S.add(s, 20000, 8);
assert.equal(s.startT, 20000, "session starts at the first real sample");
assert.equal(S.average(s, 50000), 8);
S.add(s, 30000, 0);
assert.equal(S.average(s, 50000), 8, "a skipped sample keeps the held rate");
assert.equal(S.begin().count, 0, "reset");
console.log("session: ok");

// pickBattery
const rows = [
    { batteryId: "80:C3:BA:00:9C:E8", capacity: 0 },
    { batteryId: "0F5E", capacity: 52 }
];
assert.equal(S.pickBattery(rows), "0F5E");
assert.equal(S.pickBattery([
    { batteryId: "80:C3:BA:00:9C:E8", capacity: 0 },
    { batteryId: "BAT1", capacity: 0 },
    { batteryId: "BAT0", capacity: 0 }
]), "BAT0", "all-zero capacities: first non-MAC id");
assert.equal(S.pickBattery([{ batteryId: "BAT0", capacity: 40 }, { batteryId: "BAT1", capacity: 60 }]), "BAT1");
assert.equal(S.pickBattery([]), "");
assert.equal(rows[0].batteryId, "80:C3:BA:00:9C:E8", "input is not reordered");
console.log("stats: ok");
