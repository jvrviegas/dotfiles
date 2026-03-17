import QtQuick
import QtQuick.Layouts

// Calendar & time matching calendar.lua
// Format: "Mon. 16 Mar." + "HH:MM"
Rectangle {
    id: clockRoot
    width: clockLayout.width + 16
    height: Theme.itemHeight + 2
    radius: Theme.borderRadius
    color: Theme.bg2

    border.width: 1
    border.color: Theme.black

    // Double border effect (matching sketchybar bracket)
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: Theme.borderRadius + 2
        color: "transparent"
        border.width: 2
        border.color: Theme.grey
        z: -1
    }

    RowLayout {
        id: clockLayout
        anchors.centerIn: parent
        spacing: 8

        Text {
            id: dateText
            color: Theme.white
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSizeNormal
                bold: true
            }
        }

        Text {
            id: timeText
            color: Theme.white
            font {
                family: Theme.numberFont
                pixelSize: Theme.fontSizeNormal
            }
        }
    }

    Timer {
        interval: 30000  // 30s matching sketchybar update_freq
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            dateText.text = days[now.getDay()] + ". " +
                           String(now.getDate()).padStart(2, '0') + " " +
                           months[now.getMonth()] + ".";
            timeText.text = String(now.getHours()).padStart(2, '0') + ":" +
                           String(now.getMinutes()).padStart(2, '0');
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Qt.openUrlExternally("x-scheme-handler/calendar");
        }
    }
}
