import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// Media player widget matching media.lua
// Shows current track from MPRIS (Spotify, etc.)
// Only visible when media is playing
Rectangle {
    id: mediaRoot
    visible: player !== null && player.playbackState !== MprisPlaybackState.Stopped
    width: visible ? mediaLayout.width + 16 : 0
    height: Theme.itemHeight
    radius: Theme.borderRadius
    color: Theme.bg1
    border.width: 1
    border.color: Theme.bg2

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property string trackTitle: player ? (player.trackTitle || "") : ""
    property string trackArtist: {
        if (!player || !player.trackArtists) return "";
        let artists = player.trackArtists;
        return Array.isArray(artists) ? artists.join(", ") : String(artists);
    }

    RowLayout {
        id: mediaLayout
        anchors.centerIn: parent
        spacing: 8

        // Playback controls (matching media.lua popup controls)
        Text {
            text: ""  // NerdFont previous
            color: Theme.grey
            font { family: Theme.fontFamily; pixelSize: 12 }
            MouseArea {
                anchors.fill: parent
                onClicked: { if (player) player.previous(); }
            }
        }

        Text {
            text: player && player.playbackState === MprisPlaybackState.Playing ? "" : ""
            color: Theme.white
            font { family: Theme.fontFamily; pixelSize: 14 }
            MouseArea {
                anchors.fill: parent
                onClicked: { if (player) player.togglePlaying(); }
            }
        }

        Text {
            text: ""  // NerdFont next
            color: Theme.grey
            font { family: Theme.fontFamily; pixelSize: 12 }
            MouseArea {
                anchors.fill: parent
                onClicked: { if (player) player.next(); }
            }
        }

        // Track info
        Text {
            text: {
                let display = trackTitle;
                if (trackArtist) display += " - " + trackArtist;
                return display.length > 40 ? display.substring(0, 40) + "..." : display;
            }
            color: Theme.white
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
