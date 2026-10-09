// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "battery-full"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "config/ConfigAppearance.qml"
    }
}
