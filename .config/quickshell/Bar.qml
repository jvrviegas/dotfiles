import QtQuick
import QtQuick.Layouts

Rectangle {
    id: bar
    color: Theme.barBg

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        spacing: 0

        // ===== LEFT SIDE =====

        // Workspaces
        Workspaces {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        // Active window title
        ActiveWindow {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.leftMargin: Theme.groupPadding
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // ===== RIGHT SIDE =====

        // Media (Spotify/MPRIS)
        MediaPlayer {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: Theme.groupPadding
        }

        // Calendar & Time
        Clock {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: Theme.groupPadding
        }

        // Network (WiFi)
        Network {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: Theme.groupPadding
        }

        // CPU
        CpuGraph {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: Theme.groupPadding
        }

        // Volume
        Volume {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: Theme.groupPadding
        }

        // Battery
        Battery {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: Theme.groupPadding
        }
    }
}
