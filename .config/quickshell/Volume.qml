import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Volume widget matching volume.lua
// Shows speaker icon + percentage
// Scroll to adjust volume (ctrl+scroll for fine-tuning)
Rectangle {
    id: volumeRoot
    width: volumeLayout.width + 16
    height: Theme.itemHeight
    radius: Theme.borderRadius
    color: Theme.bg1
    border.width: 1
    border.color: Theme.bg2

    property var sink: Pipewire.defaultAudioSink
    property int volume: sink ? Math.round(sink.audio.volume * 100) : 0
    property bool muted: sink ? sink.audio.muted : false

    property string volumeIcon: {
        if (muted || volume === 0) return "󰝟";    // muted
        if (volume > 60) return "";               // high
        if (volume > 30) return "󰖀";              // medium
        if (volume > 10) return "";               // low
        return "";                                // very low
    }

    RowLayout {
        id: volumeLayout
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: volumeIcon
            color: Theme.grey
            font {
                family: Theme.fontFamily
                pixelSize: 14
            }
        }

        Text {
            text: String(volume).padStart(2, '0') + "%"
            color: Theme.white
            font {
                family: Theme.numberFont
                pixelSize: Theme.fontSizeNormal
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.exec(["sh", "-c", "pavucontrol"]);
            } else if (sink) {
                sink.audio.muted = !sink.audio.muted;
            }
        }

        // Scroll to adjust volume (matching sketchybar scroll behavior)
        onWheel: wheel => {
            if (!sink) return;
            // ctrl+scroll = fine adjustment (1%), normal scroll = 10%
            let delta = wheel.modifiers & Qt.ControlModifier ? 0.01 : 0.05;
            if (wheel.angleDelta.y > 0) {
                sink.audio.volume = Math.min(1.0, sink.audio.volume + delta);
            } else {
                sink.audio.volume = Math.max(0.0, sink.audio.volume - delta);
            }
        }
    }
}
