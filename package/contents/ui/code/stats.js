// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later
//
// Pure helpers for bands, bar scale, battery choice and session statistics.
// No QML dependencies so the node tests can load this file directly.

// 0 low, 1 normal, 2 high.
function band(w, low, high) {
    if (w > high) {
        return 2;
    }
    return w >= low ? 1 : 0;
}

function barMax(auto, high, fixed) {
    return Math.max(1, auto ? high * 1.5 : fixed);
}

var MAC_RE = /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/i;

// Battery for "Automatic" out of [{ batteryId, capacity }]: the largest
// capacity, preferring ids that don't look like a Bluetooth address (headsets,
// mice), then id order. "" when there are none.
function pickBattery(rows) {
    var sorted = rows.slice().sort(function (a, b) {
        var ca = a.capacity || 0, cb = b.capacity || 0;
        if (ca !== cb) {
            return cb - ca;
        }
        var ma = MAC_RE.test(a.batteryId), mb = MAC_RE.test(b.batteryId);
        if (ma !== mb) {
            return ma ? 1 : -1;
        }
        return a.batteryId < b.batteryId ? -1 : a.batteryId > b.batteryId ? 1 : 0;
    });
    return sorted.length > 0 ? sorted[0].batteryId : "";
}

// Session accumulator, times in ms and rates in W. Each reported rate is held
// until the next report, so the average is time-weighted and stays correct
// for UPower's irregular update intervals.
function begin() {
    return { startT: 0, lastT: 0, lastW: 0, integral: 0, peak: 0, count: 0 };
}

function add(state, now, w) {
    if (!(w > 0)) {
        return;
    }
    if (state.count === 0) {
        state.startT = now;
    } else {
        state.integral += state.lastW * (now - state.lastT);
    }
    state.lastT = now;
    state.lastW = w;
    state.peak = Math.max(state.peak, w);
    state.count += 1;
}

function average(state, now) {
    if (state.count === 0) {
        return 0;
    }
    var span = now - state.startT;
    if (!(span > 0)) {
        return state.lastW;
    }
    return (state.integral + state.lastW * Math.max(0, now - state.lastT)) / span;
}
