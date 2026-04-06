import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: Theme.barHeight
            exclusiveZone: Theme.barHeight
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-bar"
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.95)

            Bar {
                anchors.fill: parent
                screen: modelData
            }
        }
    }
}
