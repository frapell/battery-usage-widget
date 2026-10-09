// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2

// Edits a power in W with one decimal. SpinBox only handles integers, so
// it works in tenths of a watt internally.
QQC2.SpinBox {
    id: control

    // W
    property real watts: 0
    property real minimumWatts: 0.1
    property real maximumWatts: 500

    signal edited(real watts)

    from: Math.round(minimumWatts * 10)
    to: Math.round(maximumWatts * 10)
    stepSize: 5
    editable: true
    value: Math.round(watts * 10)

    textFromValue: (v, locale) => Number(v / 10).toLocaleString(locale, "f", 1) + " W"
    valueFromText: (text, locale) => {
        let w = NaN;
        try {
            w = Number.fromLocaleString(locale, text.replace(/\s*W\s*$/i, "").trim());
        } catch (e) {
            w = parseFloat(text);
        }
        return isNaN(w) ? control.value : Math.round(w * 10);
    }
    validator: RegularExpressionValidator {
        regularExpression: /^\s*[0-9]+([.,][0-9]?)?\s*(W)?\s*$/i
    }

    onValueModified: edited(value / 10)
}
