pragma Singleton
import QtQuick

// Monokai Pro color scheme matching sketchybar colors.lua
QtObject {
    // Core colors
    readonly property color black: "#181819"
    readonly property color white: "#e2e2e3"
    readonly property color red: "#fc5d7c"
    readonly property color green: "#9ed072"
    readonly property color blue: "#76cce0"
    readonly property color yellow: "#e7c664"
    readonly property color orange: "#f39660"
    readonly property color magenta: "#b39df3"
    readonly property color grey: "#7f8490"

    // Background colors
    readonly property color barBg: "#aa1a1c26"          // Semi-transparent
    readonly property color barBorder: "#2c2e34"
    readonly property color popupBg: "#c02c2e34"
    readonly property color popupBorder: "#7f8490"
    readonly property color bg1: "#363944"
    readonly property color bg2: "#414550"

    // Fonts
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string numberFont: "JetBrainsMono Nerd Font"
    readonly property int fontSizeSmall: 9
    readonly property int fontSizeNormal: 12
    readonly property int fontSizeLarge: 14

    // Dimensions
    readonly property int barHeight: 40
    readonly property int itemHeight: 28
    readonly property int borderRadius: 9
    readonly property int padding: 3
    readonly property int groupPadding: 5

    // Helper: CPU color based on load
    function cpuColor(load) {
        if (load > 80) return red;
        if (load > 60) return orange;
        if (load > 30) return yellow;
        return blue;
    }

    // Helper: Battery color based on charge
    function batteryColor(charge, charging) {
        if (charging) return green;
        if (charge > 80) return green;
        if (charge > 20) return orange;
        return red;
    }
}
