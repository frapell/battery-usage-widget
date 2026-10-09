// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.kitemmodels as KItemModels
import org.kde.ksysguard.sensors as Sensors

import "../code/stats.js" as Stats

// Batteries known to ksystemstats, as a ListModel of
// { batteryId, label, name, capacity, present }. The first entry is always
// "auto". `keepId` is listed even when absent so a saved choice for a
// disconnected device isn't lost. ksystemstats also lists Bluetooth devices
// (headsets, mice), so `autoId` is the laptop battery as best we can tell.
QtObject {
    id: batteries

    property string keepId: "auto"
    readonly property ListModel model: ListModel {}
    // Bumped after every rebuild.
    property int revision: 0
    // What "auto" resolves to, "" while nothing is known.
    property string autoId: ""

    // Names and capacities survive rebuilds, so autoId doesn't flap when an
    // unrelated device appears or goes away.
    property var _known: ({})

    // Scanned directly: a filter proxy on top of the descendants model floods
    // the log with "invalid inserted rows" warnings.
    readonly property var _flat: KItemModels.KDescendantsProxyModel {
        model: Sensors.SensorTreeModel {}
        onRowsInserted: batteries._debounce.restart()
        onRowsRemoved: batteries._debounce.restart()
        onModelReset: batteries._debounce.restart()
    }

    readonly property Timer _debounce: Timer {
        interval: 200
        onTriggered: batteries.rebuild()
    }

    readonly property Instantiator _details: Instantiator {
        model: batteries.model
        delegate: QtObject {
            id: details

            required property int index
            required property string batteryId

            readonly property Sensors.Sensor nameSensor: Sensors.Sensor {
                sensorId: details.batteryId === "auto" ? "" : "power/" + details.batteryId + "/name"
                onValueChanged: batteries.setDetail(details.index, details.batteryId, "name", value || "")
            }
            readonly property Sensors.Sensor capacitySensor: Sensors.Sensor {
                sensorId: details.batteryId === "auto" ? "" : "power/" + details.batteryId + "/capacity"
                updateRateLimit: 10000
                onValueChanged: batteries.setDetail(details.index, details.batteryId, "capacity", value || 0)
            }
        }
    }

    function labelFor(id, name, capacity) {
        let label = name ? i18nc("@item:inlistbox battery name, battery id", "%1 (%2)", name, id) : id;
        if (capacity > 0) {
            label = i18nc("@item:inlistbox battery, capacity", "%1 · %2 Wh", label, Math.round(capacity));
        }
        return label;
    }

    function rebuild() {
        const ids = [];
        for (let i = 0; i < _flat.rowCount(); ++i) {
            const sensorId = _flat.data(_flat.index(i, 0), Sensors.SensorTreeModel.SensorId) || "";
            if (!/^power\/[^\/]+\/chargeRate$/.test(sensorId)) {
                continue;
            }
            const id = sensorId.split("/")[1];
            if (ids.indexOf(id) === -1) {
                ids.push(id);
            }
        }
        ids.sort();

        model.clear();
        model.append({ batteryId: "auto", label: i18nc("@item:inlistbox battery", "Automatic"),
                       name: "", capacity: 0, present: true });
        for (const id of ids) {
            const known = _known[id] || { name: "", capacity: 0 };
            model.append({ batteryId: id, label: labelFor(id, known.name, known.capacity),
                           name: known.name, capacity: known.capacity, present: true });
        }
        if (keepId !== "auto" && ids.indexOf(keepId) === -1) {
            model.append({ batteryId: keepId, label: i18nc("@item:inlistbox battery id", "%1 (not present)", keepId),
                           name: "", capacity: 0, present: false });
        }
        updateAutoId();
        ++revision;
    }

    function setDetail(index, id, key, value) {
        if (index >= model.count || model.get(index).batteryId !== id) {
            return;
        }
        const known = _known[id] || { name: "", capacity: 0 };
        known[key] = value;
        _known[id] = known;
        model.setProperty(index, key, value);
        if (model.get(index).present) {
            model.setProperty(index, "label", labelFor(id, known.name, known.capacity));
        }
        if (key === "capacity") {
            updateAutoId();
        }
    }

    function updateAutoId() {
        const rows = [];
        for (let i = 0; i < model.count; ++i) {
            const row = model.get(i);
            if (row.present && row.batteryId !== "auto") {
                rows.push({ batteryId: row.batteryId, capacity: row.capacity });
            }
        }
        autoId = Stats.pickBattery(rows);
    }

    Component.onCompleted: _debounce.start()
}
