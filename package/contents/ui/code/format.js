// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later
//
// Pure formatting helpers. No QML dependencies so the node tests can load
// this file directly.
//
// `opts` everywhere is { decimals, timeFormat, locale, separator }:
//   decimals   - digits after the separator for watts
//   timeFormat - 0 "2:45", 1 "2h 45m", 2 "2.8 h", 3 hidden
//   locale     - Qt.locale() or null (falls back to toFixed)
//   separator  - between watts and time, " · " when unset ("\n" stacks them)

var UNKNOWN = "—";

function formatNumber(value, decimals, locale) {
    if (locale) {
        return Number(value).toLocaleString(locale, "f", decimals);
    }
    return Number(value).toFixed(decimals);
}

function pad2(n) {
    return n < 10 ? "0" + n : "" + n;
}

function formatWatts(w, opts) {
    var v = w > 0 ? w : 0;
    return formatNumber(v, opts.decimals, opts.locale) + " W";
}

function formatEnergy(wh, locale) {
    return formatNumber(wh > 0 ? wh : 0, 1, locale) + " Wh";
}

// Remaining time. Rounds to whole minutes first, so 2h 59m 36s is "3:00".
function formatDuration(ms, fmt, locale) {
    if (fmt === 3) {
        return "";
    }
    if (!(ms > 0)) {
        return UNKNOWN;
    }
    var minutes = Math.round(ms / 60000);
    var h = Math.floor(minutes / 60);
    var m = minutes % 60;
    switch (fmt) {
    case 1:
        if (h === 0) {
            return m + "m";
        }
        return m === 0 ? h + "h" : h + "h " + m + "m";
    case 2:
        return formatNumber(minutes / 60, 1, locale) + " h";
    default:
        return h + ":" + pad2(m);
    }
}

function separator(opts) {
    return opts.separator || " · ";
}

// Panel text. A rate of 0 means UPower is still estimating: only "—".
function compactText(w, ms, opts) {
    if (!(w > 0)) {
        return UNKNOWN;
    }
    var duration = formatDuration(ms, opts.timeFormat, opts.locale);
    return formatWatts(w, opts) + (duration ? separator(opts) + duration : "");
}

// Strings at least as wide as anything compactText produces for rates
// under 100 W and times under 100 h, used to reserve a stable label width.
function widestTexts(opts) {
    var watts = formatNumber(100 - Math.pow(10, -opts.decimals), opts.decimals, opts.locale) + " W";
    var durations = ["99:59", "99h 59m", formatNumber(99.9, 1, opts.locale) + " h", ""];
    var duration = durations[opts.timeFormat] ?? durations[0];
    return [watts + (duration ? separator(opts) + duration : ""), UNKNOWN];
}
