import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Upower

// Battery widget matching battery.lua
// Shows icon + percentage, color-coded by level
Rectangle {
    id: batteryRoot
    width: batteryLayout.width + 16
    height: Theme.itemHeight
    radius: Theme.borderRadius
    color: Theme.bg1
    border.width: 1
    border.color: Theme.bg2

    // Use UPower for battery info
    property var battery: Upower.displayDevice
    property int charge: battery ? Math.round(battery.percentage) : 0
    property bool charging: battery ? (battery.state === UpowerDeviceState.Charging) : false

    property string batteryIcon: {
        if (charging) return "";  // NerdFont charging
        if (charge > 80) return "";
        if (charge > 60) return "";
        if (charge > 40) return "";
        if (charge > 20) return "";
        return "";
    }

    property color iconColor: Theme.batteryColor(charge, charging)

    RowLayout {
        id: batteryLayout
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: batteryIcon
            color: iconColor
            font {
                family: Theme.fontFamily
                pixelSize: 16
            }
        }

        Text {
            text: String(charge).padStart(2, '0') + "%"
            color: Theme.white
            font {
                family: Theme.numberFont
                pixelSize: Theme.fontSizeNormal
            }
        }
    }
}
