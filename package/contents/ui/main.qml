// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors

import "code/format.js" as Format
import "code/stats.js" as Stats
import "components"

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration

    // Desktop, plasmawindowed and the like show the full view directly.
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                    || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool fullShown: expanded || !inPanel

    readonly property var formatOpts: ({
        decimals: cfg.decimals,
        timeFormat: cfg.timeFormat,
        locale: Qt.locale()
    })

    // Band thresholds in W; the config page keeps low < high, this enforces it.
    readonly property real normalLow: Math.max(0.1, cfg.normalLow)
    readonly property real normalHigh: Math.max(normalLow + 0.1, cfg.normalHigh)

    BatteryModel {
        id: batteries
        keepId: root.cfg.batteryId || "auto"
    }

    readonly property string batteryId: (cfg.batteryId || "auto") === "auto" ? batteries.autoId : cfg.batteryId

    function sensorFor(key) {
        return batteryId ? "power/" + batteryId + "/" + key : "";
    }

    // W, positive while charging, negative while discharging.
    Sensors.Sensor {
        id: rateSensor
        sensorId: root.sensorFor("chargeRate")
        updateRateLimit: 1000
    }
    // Wh
    Sensors.Sensor {
        id: chargeSensor
        sensorId: root.sensorFor("charge")
        updateRateLimit: 1000
    }
    Sensors.Sensor {
        id: percentSensor
        sensorId: root.sensorFor("chargePercentage")
        updateRateLimit: 5000
    }
    Sensors.Sensor {
        id: nameSensor
        sensorId: root.sensorFor("name")
    }
    // Wh
    Sensors.Sensor {
        id: capacitySensor
        sensorId: root.sensorFor("capacity")
        updateRateLimit: 10000
    }
    // Wh
    Sensors.Sensor {
        id: designSensor
        sensorId: root.sensorFor("design")
        updateRateLimit: 10000
    }
    // %
    Sensors.Sensor {
        id: healthSensor
        sensorId: root.sensorFor("health")
        updateRateLimit: 10000
    }

    // Private API, isolated so a missing or changed module only costs the
    // smoothed time estimate; the sign of chargeRate stands in for the state.
    Loader {
        id: powerLoader
        source: "components/PowerState.qml"
    }
    readonly property var powerState: powerLoader.status === Loader.Ready ? powerLoader.item : null
    readonly property bool powerOk: powerState !== null && powerState.hasBatteries

    readonly property bool sensorsOk: rateSensor.status === Sensors.Sensor.Ready
                                      && chargeSensor.status === Sensors.Sensor.Ready

    readonly property real rate: sensorsOk ? (rateSensor.value || 0) : 0
    // By state, not by "plugged in": a charger that can't keep up still
    // drains the battery.
    readonly property bool discharging: powerOk ? powerState.discharging : rate < -0.05
    readonly property bool charging: powerOk ? powerState.charging : rate > 0.05
    readonly property bool fullyCharged: powerOk ? powerState.fullyCharged : !discharging && percent >= 99.5

    // W drawn from the battery; 0 while discharging means UPower is still
    // estimating.
    readonly property real watts: discharging ? Math.max(0, -rate) : 0
    readonly property int band: Stats.band(watts, normalLow, normalHigh)
    readonly property color bandColor: [cfg.lowColor, cfg.normalColor, cfg.highColor][band]
    readonly property real barMax: Stats.barMax(cfg.barMaxAuto, normalHigh, cfg.barMaxFixed)

    readonly property real chargeWh: sensorsOk ? (chargeSensor.value || 0) : 0
    readonly property real capacityWh: capacitySensor.value || 0
    readonly property real designWh: designSensor.value || 0
    readonly property real healthPercent: healthSensor.value || 0
    readonly property real percent: percentSensor.status === Sensors.Sensor.Ready
                                    ? (percentSensor.value || 0)
                                    : (powerOk ? powerState.percent : 0)
    readonly property string batteryName: nameSensor.value || batteryId

    // ms, 0 when unknown.
    readonly property real remainingMs: {
        if (!discharging) {
            return 0;
        }
        if (powerOk && powerState.smoothedRemainingMsec > 0) {
            return powerState.smoothedRemainingMsec;
        }
        return watts > 0 && chargeWh > 0 ? chargeWh / watts * 3.6e6 : 0;
    }

    readonly property bool showsPower: sensorsOk && discharging

    Session {
        id: session
    }

    // Refreshed every second while the popup is open; otherwise the average
    // moves on with each new sample.
    property real now: Date.now()
    readonly property real average: {
        session.revision;
        now;
        return session.average(Date.now());
    }
    readonly property real peak: session.peak
    readonly property bool sessionEmpty: session.empty

    Timer {
        interval: 1000
        running: root.fullShown
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    // The first sample may arrive before or after the state flips, so it is
    // added here too; a duplicate adds nothing to the average.
    onDischargingChanged: {
        if (discharging) {
            session.reset();
            session.add(watts);
        }
    }
    onBatteryIdChanged: session.reset()
    onRateChanged: if (discharging) session.add(watts)

    function watt(w) {
        return Format.formatWatts(w, formatOpts);
    }

    function energy(wh) {
        return Format.formatEnergy(wh, Qt.locale());
    }

    // The popup and tooltip always show the time, in h:mm when the panel hides it.
    function duration(ms) {
        return Format.formatDuration(ms, cfg.timeFormat === 3 ? 0 : cfg.timeFormat, Qt.locale());
    }

    function percentText(p) {
        return i18nc("@info percentage", "%1%", Math.round(p));
    }

    // The panel hides the applet when there is nothing to show; Edit Mode
    // still shows it so the settings stay reachable. Missing sensors keep it
    // visible so the problem doesn't go unnoticed.
    Plasmoid.status: !inPanel || showsPower || cfg.pluggedInMode !== 0 || !sensorsOk
                     ? PlasmaCore.Types.ActiveStatus
                     : PlasmaCore.Types.HiddenStatus
    Plasmoid.icon: "battery-full"

    toolTipMainText: {
        if (!sensorsOk) {
            return i18n("Battery Usage");
        }
        if (!discharging) {
            return fullyCharged ? i18n("Fully charged") : i18n("Plugged in");
        }
        if (!(watts > 0)) {
            return i18n("Estimating power draw…");
        }
        return remainingMs > 0
            ? i18nc("@info:tooltip power draw, time", "%1 · %2 remaining", watt(watts), duration(remainingMs))
            : watt(watts);
    }
    toolTipSubText: {
        if (!sensorsOk) {
            return i18n("No battery sensor available");
        }
        if (!discharging) {
            return i18nc("@info:tooltip battery name, charge", "%1 · %2", batteryName, percentText(percent));
        }
        let text = i18nc("@info:tooltip battery name, charge, energy", "%1 · %2 · %3 left",
                         batteryName, percentText(percent), energy(chargeWh));
        if (!sessionEmpty) {
            text += "\n" + i18nc("@info:tooltip", "Average %1 · Peak %2 since unplugging",
                                 watt(average), watt(peak));
        }
        return text;
    }

    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
}
