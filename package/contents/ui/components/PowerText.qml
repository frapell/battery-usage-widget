// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3

import "../code/format.js" as Format

// "9.8 W · 2:45" label that reserves the width of the widest usual value,
// so the panel item doesn't jitter as numbers change. Larger values (over
// 100 W or 100 h) may still widen it.
PlasmaComponents3.Label {
    id: label

    property real watts: 0
    property real remainingMs: 0
    property var opts
    property bool available: true
    // Lines to reserve height for, so "—" doesn't shrink a stacked label.
    readonly property int reservedLines: opts && opts.separator === "\n" && opts.timeFormat !== 3 ? 2 : 1

    readonly property real reservedWidth: {
        metrics.font; // re-measure when the font changes
        return widthFor(opts);
    }

    // Width needed for any value formatted with `o`, line by line when the
    // separator stacks watts over time.
    function widthFor(o) {
        let widest = 0;
        for (const t of Format.widestTexts(o)) {
            for (const line of t.split("\n")) {
                widest = Math.max(widest, metrics.advanceWidth(line));
            }
        }
        return Math.ceil(widest) + 1;
    }

    text: available ? Format.compactText(watts, remainingMs, opts) : "—"
    textFormat: Text.PlainText
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.features: { "tnum": 1 }
    elide: Text.ElideNone

    Layout.minimumWidth: Math.max(reservedWidth, implicitWidth)
    Layout.preferredWidth: Math.max(reservedWidth, implicitWidth)
    Layout.minimumHeight: Math.ceil(metrics.height + (reservedLines - 1) * metrics.lineSpacing)

    FontMetrics {
        id: metrics
        font: label.font
    }
}
