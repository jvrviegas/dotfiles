import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        let spotify = null;
        let playing = null;
        for (const p of players) {
            if (p.identity === "Spotify") spotify = p;
            if (p.playbackState === MprisPlaybackState.Playing && !playing) playing = p;
        }
        return spotify ?? playing ?? players[0] ?? null;
    }
    readonly property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string title: player?.trackTitle ?? ""

    visible: player !== null && title.length > 0
    implicitWidth: visible ? row.width + Theme.pillPadding * 2 : 0
    implicitHeight: Theme.pillHeight
    radius: Theme.roundingFull
    color: Theme.surfaceContainer

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.isPlaying ? "play_circle" : "pause_circle"
            color: Theme.primary
            font.family: Theme.materialFont
            font.pixelSize: Theme.materialIconSize
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }

        Text {
            readonly property string display: {
                let s = "";
                if (root.artist.length > 0) s += root.artist + " - ";
                s += root.title;
                return s;
            }
            text: display
            color: root.isPlaying ? Theme.textColor : Theme.grey
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, 250)
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering

            opacity: root.isPlaying ? 1 : 0.6
            Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.player?.togglePlaying()
    }
}
