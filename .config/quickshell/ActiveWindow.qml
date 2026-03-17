import QtQuick
import Quickshell.Hyprland

// Active window title matching front_app.lua
Rectangle {
    width: activeText.width + 16
    height: Theme.itemHeight
    radius: Theme.borderRadius
    color: Theme.bg1
    border.width: 1
    border.color: Theme.bg2

    Text {
        id: activeText
        anchors.centerIn: parent

        property string windowTitle: {
            let w = Hyprland.focusedWindow;
            if (!w) return "";
            // Show class name (app name), truncated
            let title = w.windowClass || "Desktop";
            return title.length > 30 ? title.substring(0, 30) + "..." : title;
        }

        text: windowTitle
        color: Theme.white
        font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSizeNormal
        }
    }
}
