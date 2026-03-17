import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// CPU widget matching cpu.lua
// Shows a mini graph + percentage, color-coded by load
Rectangle {
    id: cpuRoot
    width: cpuLayout.width + 16
    height: Theme.itemHeight
    radius: Theme.borderRadius
    color: Theme.bg1
    border.width: 1
    border.color: Theme.bg2

    property int cpuLoad: 0
    property color graphColor: Theme.cpuColor(cpuLoad)

    // History for the mini graph (last 20 samples)
    property var history: []

    RowLayout {
        id: cpuLayout
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: ""  // NerdFont CPU icon
            color: Theme.white
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSizeNormal
            }
        }

        // Mini graph canvas
        Canvas {
            id: graphCanvas
            width: 42
            height: 22

            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (cpuRoot.history.length < 2) return;

                ctx.beginPath();
                ctx.strokeStyle = Qt.rgba(graphColor.r, graphColor.g, graphColor.b, 0.8);
                ctx.lineWidth = 1.5;

                let step = width / (20 - 1);
                for (let i = 0; i < cpuRoot.history.length; i++) {
                    let x = i * step;
                    let y = height - (cpuRoot.history[i] / 100 * height);
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.stroke();

                // Fill under the line
                ctx.lineTo((cpuRoot.history.length - 1) * step, height);
                ctx.lineTo(0, height);
                ctx.closePath();
                ctx.fillStyle = Qt.rgba(graphColor.r, graphColor.g, graphColor.b, 0.15);
                ctx.fill();
            }
        }

        Text {
            text: "cpu " + String(cpuLoad).padStart(2, ' ') + "%"
            color: Theme.white
            font {
                family: Theme.numberFont
                pixelSize: Theme.fontSizeSmall
                bold: true
            }
        }
    }

    // Poll CPU load every 2 seconds (matching sketchybar cpu_load interval)
    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu / {usage=($2+$4)*100/($2+$4+$5); printf \"%.0f\", usage}' /proc/stat"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                let load = parseInt(data) || 0;
                cpuRoot.cpuLoad = load;

                let h = cpuRoot.history.slice();
                h.push(load);
                if (h.length > 20) h.shift();
                cpuRoot.history = h;

                graphCanvas.requestPaint();
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: cpuProc.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Quickshell.exec(["sh", "-c", "gnome-system-monitor || htop"]);
        }
    }

    Behavior on graphColor { ColorAnimation { duration: 300 } }
}
