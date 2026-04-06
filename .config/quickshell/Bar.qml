import QtQuick
import QtQuick.Layouts
import Quickshell
import "components"

Item {
    id: root
    required property ShellScreen screen

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: Theme.groupSpacing

        // ===== LEFT =====
        Workspaces {
            Layout.alignment: Qt.AlignVCenter
            screen: root.screen
        }

        ActiveWindow {
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // ===== CENTER =====
        MediaPlayer {
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // ===== RIGHT =====
        SysTray {
            Layout.alignment: Qt.AlignVCenter
        }

        StatsGroup {
            Layout.alignment: Qt.AlignVCenter
        }

        StatusGroup {
            Layout.alignment: Qt.AlignVCenter
        }

        Clock {
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
