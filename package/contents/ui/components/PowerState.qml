// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.plasma.private.battery

// The only file that touches the private battery API, the one the stock
// battery applet uses. main.qml loads it with a Loader and falls back to the
// sign of chargeRate if it fails to load.
BatteryControlModel {
    // The enum only resolves where the module is imported.
    readonly property bool discharging: state === BatteryControlModel.Discharging
    readonly property bool charging: state === BatteryControlModel.Charging
    readonly property bool fullyCharged: state === BatteryControlModel.FullyCharged
}
