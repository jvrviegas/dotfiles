import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    // Create a bar for each screen
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            // Match sketchybar height
            height: 40

            // Layer shell settings
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-bar"

            // Reserve space (exclusive zone)
            exclusionMode: ExclusionMode.Normal

            color: "transparent"

            Bar {
                anchors.fill: parent
            }
        }
    }
}
