import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import ".."

// Volume + Network + Battery in one pill (Caelestia style)
Rectangle {
    id: root

    implicitWidth: row.width + Theme.pillPadding * 2
    implicitHeight: Theme.pillHeight
    radius: Theme.roundingFull
    color: Theme.surfaceContainer

    // Volume
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)

    // Battery
    readonly property var battery: UPower.displayDevice
    readonly property int charge: battery ? Math.round(battery.percentage) : 0
    readonly property bool charging: battery ? (battery.state === UPowerDeviceState.Charging) : false

    // Network
    property string netIcon: "wifi_off"
    property bool connected: false

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Process {
        id: netProc
        command: ["sh", "-c", "nmcli -t -f TYPE connection show --active 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                const type = data.trim();
                root.connected = type.length > 0;
                root.netIcon = type.includes("wireless") ? "wifi" : type.length > 0 ? "lan" : "wifi_off";
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // Volume
        Text {
            text: root.muted ? "volume_off" : root.volume > 66 ? "volume_up" : root.volume > 33 ? "volume_down" : "volume_mute"
            color: root.muted ? Theme.grey : Theme.secondary
            font.family: Theme.materialFont
            font.pixelSize: Theme.materialIconSize
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.sink?.audio)
                        root.sink.audio.muted = !root.sink.audio.muted;
                }
            }
        }

        // Network
        Text {
            text: root.netIcon
            color: root.connected ? Theme.secondary : Theme.error
            font.family: Theme.materialFont
            font.pixelSize: Theme.materialIconSize
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }

        // Battery (only if available)
        Text {
            visible: root.battery !== null
            text: {
                if (root.charging) return "battery_charging_full";
                if (root.charge > 80) return "battery_full";
                if (root.charge > 60) return "battery_5_bar";
                if (root.charge > 40) return "battery_4_bar";
                if (root.charge > 20) return "battery_2_bar";
                return "battery_alert";
            }
            color: Theme.batteryColor(root.charge, root.charging)
            font.family: Theme.materialFont
            font.pixelSize: Theme.materialIconSize
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }

        // Power
        Text {
            text: "power_settings_new"
            color: Theme.error
            font.family: Theme.materialFont
            font.pixelSize: Theme.materialIconSize
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }
    }
}
