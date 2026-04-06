import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

// CPU + Memory + Disk in one pill (Caelestia style)
Rectangle {
    id: root

    implicitWidth: row.width + Theme.pillPadding * 2
    implicitHeight: Theme.pillHeight
    radius: Theme.roundingFull
    color: Theme.surfaceContainer

    property string cpuUsage: "0"
    property string memUsage: "0"
    property string diskUsage: "0"

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { cpuProc.running = true; memProc.running = true; }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu / {usage=($2+$4)*100/($2+$4+$5); printf \"%.0f\", usage}' /proc/stat"]
        stdout: SplitParser { onRead: data => root.cpuUsage = data.trim() }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.0f\", (t-a)/t*100}' /proc/meminfo"]
        stdout: SplitParser { onRead: data => root.memUsage = data.trim() }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df / | awk 'NR==2{gsub(/%/,\"\",$5); print $5}'"]
        stdout: SplitParser { onRead: data => root.diskUsage = data.trim() }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        // CPU
        Row {
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "memory"
                color: Theme.tertiary
                font.family: Theme.materialFont
                font.pixelSize: 17
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
            Text {
                text: root.cpuUsage + "%"
                color: Theme.tertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }

        // Memory
        Row {
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "developer_board"
                color: Theme.tertiary
                font.family: Theme.materialFont
                font.pixelSize: 17
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
            Text {
                text: root.memUsage + "%"
                color: Theme.tertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }

        // Disk
        Row {
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "hard_drive"
                color: Theme.tertiary
                font.family: Theme.materialFont
                font.pixelSize: 17
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
            Text {
                text: root.diskUsage + "%"
                color: Theme.tertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }
    }
}
