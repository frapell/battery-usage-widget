// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

// Rounded track with an animated fill and colour, horizontal (left to right) or
// vertical (bottom to top).
Item {
    id: bar

    property real value: 0
    property real maximum: 1
    property color color: Kirigami.Theme.highlightColor
    property bool vertical: false

    readonly property real ratio: maximum > 0 ? Math.min(1, Math.max(0, value / maximum)) : 0
    readonly property real radius: Math.min(width, height) / 4

    Behavior on color {
        ColorAnimation { duration: Kirigami.Units.shortDuration }
    }

    Rectangle {
        anchors.fill: parent
        radius: bar.radius
        color: Qt.rgba(bar.color.r, bar.color.g, bar.color.b, 0.25)
    }

    Rectangle {
        anchors {
            left: parent.left
            bottom: parent.bottom
            top: bar.vertical ? undefined : parent.top
            right: bar.vertical ? parent.right : undefined
        }
        width: bar.vertical ? parent.width : parent.width * bar.ratio
        height: bar.vertical ? parent.height * bar.ratio : parent.height
        radius: bar.radius
        color: bar.color
        visible: bar.ratio > 0

        Behavior on width {
            enabled: !bar.vertical
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }
        Behavior on height {
            enabled: bar.vertical
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }
    }
}
