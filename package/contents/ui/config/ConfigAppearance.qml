// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

import "../code/format.js" as Format

ConfigPage {
    id: page

    // Thresholds are set on the General page.
    readonly property real normalLow: Plasmoid.configuration.normalLow
    readonly property real normalHigh: Plasmoid.configuration.normalHigh

    function watt(w) {
        return Format.formatWatts(w, { decimals: 1, locale: Qt.locale() });
    }

    Kirigami.FormLayout {
        KQuickControls.ColorButton {
            Kirigami.FormData.label: i18nc("@label %1 is a power", "Below %1:", page.watt(page.normalLow))
            color: page.cfg_lowColor
            onAccepted: (color) => page.cfg_lowColor = color
        }
        KQuickControls.ColorButton {
            Kirigami.FormData.label: i18nc("@label %1 and %2 are powers", "%1 to %2:",
                                           page.watt(page.normalLow), page.watt(page.normalHigh))
            color: page.cfg_normalColor
            onAccepted: (color) => page.cfg_normalColor = color
        }
        KQuickControls.ColorButton {
            Kirigami.FormData.label: i18nc("@label %1 is a power", "Above %1:", page.watt(page.normalHigh))
            color: page.cfg_highColor
            onAccepted: (color) => page.cfg_highColor = color
        }

        QQC2.CheckBox {
            text: i18n("Also color the text in the high band")
            checked: page.cfg_colorTextHigh
            onToggled: page.cfg_colorTextHigh = checked
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ButtonGroup { id: scaleGroup }
        QQC2.RadioButton {
            Kirigami.FormData.label: i18n("Bar scale:")
            text: i18nc("@option:radio %1 is a power", "Automatic (%1)", page.watt(1.5 * page.normalHigh))
            checked: page.cfg_barMaxAuto
            QQC2.ButtonGroup.group: scaleGroup
            onToggled: page.cfg_barMaxAuto = true
        }
        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC2.RadioButton {
                text: i18n("Fixed maximum:")
                checked: !page.cfg_barMaxAuto
                QQC2.ButtonGroup.group: scaleGroup
                onToggled: page.cfg_barMaxAuto = false
            }
            WattSpinBox {
                enabled: !page.cfg_barMaxAuto
                minimumWatts: 1
                maximumWatts: 500
                watts: page.cfg_barMaxFixed
                onEdited: (w) => page.cfg_barMaxFixed = w
            }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Panel layout:")
            model: [
                i18nc("@item:inlistbox panel layout", "Bar under the text"),
                i18nc("@item:inlistbox panel layout", "Bar with text on the right"),
                i18nc("@item:inlistbox panel layout", "Bar with text on the left"),
                i18nc("@item:inlistbox panel layout", "Bar only"),
                i18nc("@item:inlistbox panel layout", "Text only")
            ]
            currentIndex: page.cfg_textPosition
            onActivated: page.cfg_textPosition = currentIndex
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Bar length:")
            from: 1
            to: 20
            value: page.cfg_barLengthUnits
            onValueModified: page.cfg_barLengthUnits = value
            textFromValue: (v, locale) => i18ncp("@item:valuesuffix bar length", "%1 unit", "%1 units", v)
            valueFromText: (text, locale) => parseInt(text) || 4
        }

        QQC2.Label {
            visible: page.cfg_textPosition === 0
            text: i18n("Under the text the bar is as wide as the text; the length applies to vertical panels.")
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        }
    }
}
