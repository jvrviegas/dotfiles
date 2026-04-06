import QtQuick
import QtQuick.Layouts
import ".."

// Caelestia-style clock: material icon + time
Rectangle {
    id: root

    implicitWidth: row.width + Theme.pillPadding * 2
    implicitHeight: Theme.pillHeight
    radius: Theme.roundingFull
    color: Theme.surfaceContainerHigh

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: "schedule"
            color: Theme.tertiary
            font.family: Theme.materialFont
            font.pixelSize: Theme.materialIconSize
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }

        Text {
            id: clockText
            color: Theme.tertiary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd. dd MMM. HH:mm")
    }
}
