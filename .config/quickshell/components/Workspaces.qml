import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".."

// Caelestia-style workspaces: pill with dot indicators
Rectangle {
    id: root
    required property ShellScreen screen

    readonly property int activeWsId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    implicitWidth: row.width + Theme.pillPadding * 2
    implicitHeight: Theme.pillHeight
    radius: Theme.roundingFull
    color: Theme.surfaceContainer

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: 8

            Item {
                id: wsItem
                required property int index

                readonly property int wsId: index + 1
                readonly property bool active: root.activeWsId === wsId
                readonly property bool occupied: {
                    const ws = Hyprland.workspaces.values.find(w => w.id === wsId);
                    return ws !== undefined && ws !== null;
                }

                width: active ? 26 : 18
                height: 26

                Behavior on width {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: wsItem.active ? 24 : wsItem.occupied ? 8 : 5
                    height: wsItem.active ? 24 : wsItem.occupied ? 8 : 5
                    radius: Theme.roundingFull
                    color: wsItem.active ? Theme.primary : wsItem.occupied ? Theme.secondary : Theme.grey
                    opacity: wsItem.active ? 1 : wsItem.occupied ? 0.5 : 0.25

                    Behavior on width { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.animDuration } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

                    Text {
                        anchors.centerIn: parent
                        text: wsItem.wsId
                        color: Theme.primaryText
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        visible: wsItem.active
                        opacity: wsItem.active ? 1 : 0
                        renderType: Text.NativeRendering

                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`workspace ${wsItem.wsId}`)
                }
            }
        }
    }
}
