import QtQuick
import ".."

// Caelestia-style pill container
Rectangle {
    id: root

    property alias content: contentItem.children

    implicitHeight: Theme.pillHeight
    radius: Theme.roundingFull
    color: Theme.surfaceContainer

    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
