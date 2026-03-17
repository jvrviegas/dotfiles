import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Workspace switcher matching AeroSpace spaces.lua
// Shows workspaces 1-8 with highlight on focused workspace
Row {
    id: root
    spacing: 2

    Repeater {
        model: 8

        Rectangle {
            id: wsButton

            required property int index
            property int wsNumber: index + 1
            property bool focused: Hyprland.focusedWorkspace?.id === wsNumber
            property bool occupied: hasWindows()

            width: wsContent.width + 20
            height: Theme.itemHeight
            radius: Theme.borderRadius
            color: Theme.bg1

            border.width: focused ? 2 : 1
            border.color: focused ? Theme.grey : Theme.bg2

            function hasWindows() {
                for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                    let ws = Hyprland.workspaces.values[i];
                    if (ws.id === wsNumber && ws.windows > 0) return true;
                }
                return false;
            }

            RowLayout {
                id: wsContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: wsNumber
                    color: focused ? Theme.red : Theme.white
                    font {
                        family: Theme.numberFont
                        pixelSize: Theme.fontSizeNormal
                        bold: focused
                    }
                }

                // Occupied indicator dot
                Rectangle {
                    visible: occupied && !focused
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.grey
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Hyprland.dispatch("workspace " + wsNumber);
                }
            }

            // Smooth transitions
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
