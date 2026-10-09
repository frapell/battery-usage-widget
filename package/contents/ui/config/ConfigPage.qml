// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.kcmutils as KCM

// Base for every settings page. Plasma assigns every cfg_<entry> and
// cfg_<entry>Default to each page, so all of them are declared here; the
// pages read and write the ones they show.
KCM.SimpleKCM {
    property var cfg_batteryId
    property var cfg_batteryIdDefault
    property var cfg_normalLow
    property var cfg_normalLowDefault
    property var cfg_normalHigh
    property var cfg_normalHighDefault
    property var cfg_decimals
    property var cfg_decimalsDefault
    property var cfg_timeFormat
    property var cfg_timeFormatDefault
    property var cfg_timePosition
    property var cfg_timePositionDefault
    property var cfg_pluggedInMode
    property var cfg_pluggedInModeDefault
    property var cfg_lowColor
    property var cfg_lowColorDefault
    property var cfg_normalColor
    property var cfg_normalColorDefault
    property var cfg_highColor
    property var cfg_highColorDefault
    property var cfg_colorTextHigh
    property var cfg_colorTextHighDefault
    property var cfg_barMaxAuto
    property var cfg_barMaxAutoDefault
    property var cfg_barMaxFixed
    property var cfg_barMaxFixedDefault
    property var cfg_textPosition
    property var cfg_textPositionDefault
    property var cfg_barLengthUnits
    property var cfg_barLengthUnitsDefault

    // Not ours: the panel passes these to every applet's pages, which logs a
    // warning per page unless they exist.
    property var cfg_expanding
    property var cfg_expandingDefault
    property var cfg_length
    property var cfg_lengthDefault
}
