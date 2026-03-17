import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Network widget matching wifi.lua
// Shows upload/download speeds, color-coded
Rectangle {
    id: netRoot
    width: netLayout.width + 16
    height: Theme.itemHeight
    radius: Theme.borderRadius
    color: Theme.bg1
    border.width: 1
    border.color: Theme.bg2

    property string upload: "0 B/s"
    property string download: "0 B/s"
    property bool uploadActive: upload !== "0 B/s"
    property bool downloadActive: download !== "0 B/s"

    // Track previous rx/tx bytes for delta calculation
    property real prevRx: 0
    property real prevTx: 0

    RowLayout {
        id: netLayout
        anchors.centerIn: parent
        spacing: 6

        Column {
            spacing: 0

            Row {
                spacing: 2
                Text {
                    text: ""  // NerdFont upload
                    color: uploadActive ? Theme.red : Theme.grey
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall; bold: true }
                }
                Text {
                    text: upload
                    color: uploadActive ? Theme.red : Theme.grey
                    font { family: Theme.numberFont; pixelSize: Theme.fontSizeSmall; bold: true }
                }
            }

            Row {
                spacing: 2
                Text {
                    text: ""  // NerdFont download
                    color: downloadActive ? Theme.blue : Theme.grey
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall; bold: true }
                }
                Text {
                    text: download
                    color: downloadActive ? Theme.blue : Theme.grey
                    font { family: Theme.numberFont; pixelSize: Theme.fontSizeSmall; bold: true }
                }
            }
        }
    }

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B/s";
        if (bytes < 1048576) return (bytes / 1024).toFixed(0) + " KB/s";
        return (bytes / 1048576).toFixed(1) + " MB/s";
    }

    // Poll network stats every 2 seconds (matching sketchybar network_load interval)
    Process {
        id: netProc
        command: ["sh", "-c", "cat /proc/net/dev | awk '/wlan0:|wlp|enp/ {print $2, $10}'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(/\s+/);
                if (parts.length >= 2) {
                    let rx = parseFloat(parts[0]) || 0;
                    let tx = parseFloat(parts[1]) || 0;

                    if (netRoot.prevRx > 0) {
                        let rxDelta = (rx - netRoot.prevRx) / 2;  // per second
                        let txDelta = (tx - netRoot.prevTx) / 2;
                        netRoot.download = netRoot.formatBytes(Math.max(0, rxDelta));
                        netRoot.upload = netRoot.formatBytes(Math.max(0, txDelta));
                    }

                    netRoot.prevRx = rx;
                    netRoot.prevTx = tx;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Quickshell.exec(["sh", "-c", "nm-connection-editor"]);
        }
    }
}
