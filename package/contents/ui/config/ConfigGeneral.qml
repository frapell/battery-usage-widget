// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import "../code/format.js" as Format
import "../components"

ConfigPage {
    id: page

    readonly property BatteryModel batteries: BatteryModel {
        keepId: page.cfg_batteryId || "auto"
        onRevisionChanged: batteryCombo.currentIndex = batteryCombo.indexOfValue(page.cfg_batteryId || "auto")
    }

    // 2h 45m, for the examples.
    readonly property real exampleMs: (2 * 60 + 45) * 60000

    readonly property var previewOpts: ({
        decimals: cfg_decimals ?? 1,
        timeFormat: cfg_timeFormat ?? 0,
        locale: Qt.locale(),
        separator: cfg_timePosition === 1 ? undefined : "\n"
    })

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: batteryCombo
            Kirigami.FormData.label: i18n("Battery:")
            model: page.batteries.model
            textRole: "label"
            valueRole: "batteryId"
            onActivated: page.cfg_batteryId = currentValue
        }

        QQC2.Label {
            visible: (page.cfg_batteryId || "auto") === "auto" && page.batteries.autoId !== ""
            text: i18nc("@info battery id", "Currently %1", page.batteries.autoId)
            textFormat: Text.PlainText
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true }

        WattSpinBox {
            Kirigami.FormData.label: i18n("Low draw below:")
            minimumWatts: 0.1
            maximumWatts: Math.max(0.1, (page.cfg_normalHigh ?? 12) - 0.1)
            watts: page.cfg_normalLow
            onEdited: (w) => page.cfg_normalLow = w
        }

        WattSpinBox {
            Kirigami.FormData.label: i18n("High draw above:")
            minimumWatts: Math.min(500, (page.cfg_normalLow ?? 6) + 0.1)
            maximumWatts: 500
            watts: page.cfg_normalHigh
            onEdited: (w) => page.cfg_normalHigh = w
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Decimal places:")
            from: 0
            to: 2
            value: page.cfg_decimals
            onValueModified: page.cfg_decimals = value
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Time remaining:")
            model: [
                i18nc("@item:inlistbox time format, %1 is an example", "Hours:minutes (%1)",
                      Format.formatDuration(page.exampleMs, 0, Qt.locale())),
                i18nc("@item:inlistbox time format, %1 is an example", "Hours and minutes (%1)",
                      Format.formatDuration(page.exampleMs, 1, Qt.locale())),
                i18nc("@item:inlistbox time format, %1 is an example", "Decimal hours (%1)",
                      Format.formatDuration(page.exampleMs, 2, Qt.locale())),
                i18nc("@item:inlistbox time format", "Hidden")
            ]
            currentIndex: page.cfg_timeFormat
            onActivated: page.cfg_timeFormat = currentIndex
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Show the time:")
            enabled: page.cfg_timeFormat !== 3
            model: [
                i18nc("@item:inlistbox time position", "Below the power draw"),
                i18nc("@item:inlistbox time position", "Next to the power draw")
            ]
            currentIndex: page.cfg_timePosition
            onActivated: page.cfg_timePosition = currentIndex
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Example:")
            text: Format.compactText(9.8, page.exampleMs, page.previewOpts)
            textFormat: Text.PlainText
            font.features: { "tnum": 1 }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("When plugged in:")
            model: [
                i18nc("@item:inlistbox when plugged in", "Hide the widget"),
                i18nc("@item:inlistbox when plugged in", "Show a charging icon"),
                i18nc("@item:inlistbox when plugged in", "Show “AC”")
            ]
            currentIndex: page.cfg_pluggedInMode
            onActivated: page.cfg_pluggedInMode = currentIndex
        }

        QQC2.Label {
            visible: page.cfg_pluggedInMode === 0
            text: i18n("The widget stays visible in Edit Mode.")
            textFormat: Text.PlainText
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
