// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import "../code/stats.js" as Stats

// Average and peak draw since the battery started discharging. The state is
// a plain JS object mutated in place; `revision` tells bindings it changed.
QtObject {
    id: session

    property var _state: Stats.begin()
    property int revision: 0

    readonly property real peak: {
        revision;
        return _state.peak;
    }
    readonly property bool empty: {
        revision;
        return _state.count === 0;
    }

    function reset() {
        _state = Stats.begin();
        ++revision;
    }

    function add(w) {
        Stats.add(_state, Date.now(), w);
        ++revision;
    }

    function average(now) {
        return Stats.average(_state, now);
    }
}
