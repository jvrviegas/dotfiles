pragma Singleton

import QtQuick

QtObject {
    // Monokai Pro palette
    readonly property color black: "#181819"
    readonly property color white: "#e2e2e3"
    readonly property color red: "#fc5d7c"
    readonly property color green: "#9ed072"
    readonly property color blue: "#76cce0"
    readonly property color yellow: "#e7c664"
    readonly property color orange: "#f39660"
    readonly property color magenta: "#b39df3"
    readonly property color grey: "#7f8490"

    // M3 surface colors (matching Caelestia)
    readonly property color surface: "#0d0f18"
    readonly property color surfaceContainer: Qt.rgba(1, 1, 1, 0.08)
    readonly property color surfaceContainerHigh: Qt.rgba(1, 1, 1, 0.12)
    readonly property color surfaceBorder: Qt.rgba(1, 1, 1, 0.04)

    // Semantic M3 roles
    readonly property color primary: "#f5a0b0"
    readonly property color primaryText: "#1a1c26"
    readonly property color secondary: "#9a9aa8"
    readonly property color tertiary: "#b39df3"
    readonly property color error: "#fc5d7c"
    readonly property color textColor: "#ccc"

    // Fonts
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string materialFont: "Material Symbols Rounded"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int materialIconSize: 19

    // Layout
    readonly property int barHeight: 46
    readonly property int pillHeight: 34
    readonly property int roundingFull: 1000
    readonly property int roundingNormal: 14
    readonly property int pillPadding: 10
    readonly property int groupSpacing: 6

    // Animation
    readonly property int animDuration: 250
    readonly property int animDurationFast: 150

    function batteryColor(charge, charging) {
        if (charging) return green;
        if (charge > 20) return secondary;
        if (charge > 10) return yellow;
        return error;
    }
}
