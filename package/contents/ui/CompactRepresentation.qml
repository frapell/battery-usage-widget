// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "components"

Item {
    id: compact

    readonly property var cfg: Plasmoid.configuration
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // 0 bar under text, 1 text right of bar, 2 text left of bar, 3 bar only,
    // 4 text only
    readonly property int textPosition: cfg.textPosition
    readonly property real barLength: Kirigami.Units.gridUnit * Math.max(1, cfg.barLengthUnits)

    // Horizontal: time on its own line under the watts when there is room
    // for two lines (plus the bar under them in mode 0), otherwise one line.
    readonly property bool timeBelow: !vertical && cfg.timePosition === 0 && cfg.timeFormat !== 3
                                      && height >= 2 * smallMetrics.height
                                                   + (textPosition === 0 ? barHeightFor(2) + 1 : 0)
    readonly property int lines: timeBelow ? 2 : 1
    readonly property var horizontalOpts: timeBelow
        ? Object.assign({}, root.formatOpts, { separator: "\n" })
        : root.formatOpts

    readonly property bool useSmallFont: !vertical && height < (lines + 1) * defaultMetrics.height
    readonly property font textFont: useSmallFont ? Kirigami.Theme.smallFont : Kirigami.Theme.defaultFont
    readonly property real textHeight: lines * (useSmallFont ? smallMetrics.height : defaultMetrics.height)

    // Plugged in (or full) with sensors working: show the configured cue
    // instead of the reading.
    readonly property bool pluggedCue: root.sensorsOk && !root.showsPower

    readonly property color textColor: root.showsPower && root.band === 2 && cfg.colorTextHigh
                                       ? cfg.highColor : Kirigami.Theme.textColor

    // Vertical panels try progressively narrower text: watts over time, then
    // without decimals, then watts alone.
    readonly property var verticalCandidates: [
        Object.assign({}, root.formatOpts, { separator: "\n" }),
        Object.assign({}, root.formatOpts, { separator: "\n", decimals: 0 }),
        Object.assign({}, root.formatOpts, { separator: "\n", decimals: 0, timeFormat: 3 })
    ]
    readonly property int verticalFit: {
        if (!vertical) {
            return -1;
        }
        for (let i = 0; i < verticalCandidates.length; ++i) {
            if (width >= verticalText.widthFor(verticalCandidates[i])) {
                return i;
            }
        }
        return -1;
    }
    readonly property var verticalOpts: verticalCandidates[Math.max(0, verticalFit)]

    // Horizontal: the bar under the text in mode 0, thinner under two lines.
    function barHeightFor(lineCount) {
        return Math.max(2, Math.round(height * (lineCount === 2 ? 0.08 : 0.12)));
    }
    readonly property real stackedBarHeight: barHeightFor(lines)
    readonly property bool textFits: vertical ? verticalFit >= 0 : height >= smallMetrics.height
    readonly property bool stackFits: height >= textHeight + stackedBarHeight + 1

    readonly property bool showText: textPosition !== 3 && textFits
    // Text-only falls back to the bar when the text has nowhere to go. Mode 0
    // drops the bar first when both don't fit.
    readonly property bool showBar: {
        if (!showText) {
            return true;
        }
        if (textPosition === 4) {
            return false;
        }
        return textPosition !== 0 || vertical || stackFits;
    }
    readonly property bool stacked: !vertical && textPosition === 0 && showText && showBar

    readonly property Item content: pluggedCue ? cue
        : vertical ? verticalLayout
        : stacked ? stackedLayout
        : rowLayout

    Layout.minimumWidth: vertical ? -1 : content.implicitWidth
    Layout.preferredWidth: vertical ? -1 : content.implicitWidth
    Layout.maximumWidth: vertical ? -1 : content.implicitWidth
    Layout.minimumHeight: vertical ? content.implicitHeight : -1
    Layout.preferredHeight: vertical ? content.implicitHeight : -1
    Layout.maximumHeight: vertical ? content.implicitHeight : -1

    FontMetrics {
        id: defaultMetrics
        font: Kirigami.Theme.defaultFont
    }

    FontMetrics {
        id: smallMetrics
        font: Kirigami.Theme.smallFont
    }

    component Reading: PowerText {
        watts: root.watts
        remainingMs: root.remainingMs
        opts: compact.horizontalOpts
        available: root.sensorsOk
        color: compact.textColor

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    component Bar: BandBar {
        value: root.watts
        maximum: root.barMax
        color: root.bandColor
    }

    // Mode 0: text over a thin bar of the same width.
    ColumnLayout {
        id: stackedLayout

        visible: compact.content === stackedLayout
        anchors.centerIn: parent
        spacing: 1

        Reading {
            font: compact.textFont
            Layout.fillWidth: true
        }
        Bar {
            Layout.fillWidth: true
            Layout.preferredHeight: compact.stackedBarHeight
        }
    }

    // Modes 1-4, and mode 0 when only one of text and bar fits.
    RowLayout {
        id: rowLayout

        visible: compact.content === rowLayout
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Kirigami.Units.smallSpacing
        layoutDirection: compact.textPosition === 2 ? Qt.RightToLeft : Qt.LeftToRight

        Bar {
            visible: compact.showBar
            Layout.preferredWidth: compact.barLength
            Layout.preferredHeight: Math.max(2, Math.round(compact.height * 0.3))
            Layout.alignment: Qt.AlignVCenter
        }
        Reading {
            visible: compact.showText
            font: compact.textFont
            horizontalAlignment: compact.textPosition === 1 ? Text.AlignLeft
                               : compact.textPosition === 2 ? Text.AlignRight
                               : Text.AlignHCenter
            Layout.fillHeight: true
        }
    }

    // Vertical panel: watts over time over a full-width bar, or a vertical
    // bar alone.
    ColumnLayout {
        id: verticalLayout

        visible: compact.content === verticalLayout
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: Kirigami.Units.smallSpacing

        Reading {
            id: verticalText
            visible: compact.showText
            opts: compact.verticalOpts
            font: Kirigami.Theme.smallFont
            Layout.fillWidth: true
        }
        Bar {
            visible: compact.showBar && compact.showText
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(2, Math.round(Kirigami.Units.gridUnit * 0.25))
        }
        Bar {
            visible: compact.showBar && !compact.showText
            vertical: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.max(2, Math.min(Kirigami.Units.gridUnit * 0.6, compact.width))
            Layout.preferredHeight: compact.barLength
        }
    }

    // Plugged in. With "hide" the panel collapses the applet, so the dimmed
    // icon only shows in Edit Mode.
    Item {
        id: cue

        readonly property real thickness: compact.vertical ? compact.width : compact.height
        readonly property bool showLabel: compact.cfg.pluggedInMode === 2

        visible: compact.content === cue
        anchors.centerIn: parent
        implicitWidth: showLabel ? acLabel.implicitWidth : thickness
        implicitHeight: showLabel ? acLabel.implicitHeight : thickness
        width: implicitWidth
        height: implicitHeight

        Kirigami.Icon {
            anchors.fill: parent
            visible: !cue.showLabel
            source: compact.cfg.pluggedInMode === 1 && root.fullyCharged ? "battery-full" : "battery-full-charging"
            opacity: compact.cfg.pluggedInMode === 0 ? 0.4 : 1
        }
        PlasmaComponents3.Label {
            id: acLabel
            anchors.centerIn: parent
            visible: cue.showLabel
            text: root.fullyCharged ? root.percentText(100) : i18nc("@label plugged in", "AC")
            font: compact.vertical ? Kirigami.Theme.smallFont : compact.textFont
            textFormat: Text.PlainText
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.expanded = !root.expanded
    }
}
