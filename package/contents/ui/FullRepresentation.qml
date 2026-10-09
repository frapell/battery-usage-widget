// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: full

    readonly property var cfg: Plasmoid.configuration
    readonly property bool hasSession: root.showsPower && !root.sessionEmpty

    Layout.minimumWidth: Kirigami.Units.gridUnit * 16
    Layout.preferredWidth: Kirigami.Units.gridUnit * 20

    spacing: Kirigami.Units.largeSpacing

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: !root.sensorsOk
        type: Kirigami.MessageType.Warning
        text: root.batteryId
            ? i18n("Battery %1 is not available.", root.batteryId)
            : i18n("No battery data from ksystemstats. Make sure the plasma-ksystemstats service is running.")
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: root.sensorsOk && !root.discharging
        type: Kirigami.MessageType.Information
        text: i18n("Statistics resume when the battery is discharging.")
    }

    component Value: PlasmaComponents3.Label {
        textFormat: Text.PlainText
        font.features: { "tnum": 1 }
    }

    Kirigami.FormLayout {
        Layout.fillWidth: true

        RowLayout {
            Kirigami.FormData.label: i18n("Battery:")
            spacing: Kirigami.Units.smallSpacing

            Value {
                text: root.sensorsOk ? root.batteryName : "—"
            }
            Value {
                visible: root.sensorsOk && root.batteryName !== root.batteryId
                text: root.batteryId
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
        }

        Value {
            Kirigami.FormData.label: i18n("State:")
            text: !root.sensorsOk ? "—"
                : root.discharging ? i18nc("@info battery state", "Discharging")
                : root.charging ? i18nc("@info battery state", "Charging")
                : root.fullyCharged ? i18nc("@info battery state", "Fully charged")
                : i18nc("@info battery state", "Not charging")
        }

        Value {
            Kirigami.FormData.label: i18n("Power draw:")
            text: !root.showsPower ? "—"
                : root.watts > 0 ? root.watt(root.watts)
                : i18nc("@info power draw not known yet", "Estimating…")
            color: root.showsPower && root.watts > 0 ? root.bandColor : Kirigami.Theme.textColor
            font.bold: root.showsPower && root.watts > 0
        }

        Value {
            Kirigami.FormData.label: i18n("Average since unplugging:")
            text: full.hasSession ? root.watt(root.average) : "—"
        }

        Value {
            Kirigami.FormData.label: i18n("Peak since unplugging:")
            text: full.hasSession ? root.watt(root.peak) : "—"
        }

        Value {
            Kirigami.FormData.label: i18n("Time remaining:")
            text: root.duration(root.remainingMs)
        }

        Value {
            Kirigami.FormData.label: i18n("Charge:")
            text: root.sensorsOk ? root.percentText(root.percent) : "—"
        }

        Value {
            Kirigami.FormData.label: i18n("Energy left:")
            text: !root.sensorsOk ? "—"
                : root.capacityWh > 0
                ? i18nc("@info energy now, energy when full", "%1 of %2", root.energy(root.chargeWh), root.energy(root.capacityWh))
                : root.energy(root.chargeWh)
        }

        Value {
            Kirigami.FormData.label: i18n("Health:")
            visible: root.sensorsOk && root.designWh > 0
            text: root.percentText(root.healthPercent)
        }
    }

    Item {
        Layout.fillHeight: true
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        text: i18n("Updates about every 30 s from UPower")
    }
}
