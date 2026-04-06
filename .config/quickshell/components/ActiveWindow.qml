import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".."

// Active window: material icon + title in a pill
Rectangle {
    id: root

    readonly property var toplevel: Hyprland.activeToplevel
    readonly property string title: toplevel?.title ?? ""

    visible: title.length > 0
    implicitWidth: visible ? row.width + Theme.pillPadding * 2 : 0
    implicitHeight: Theme.pillHeight
    radius: Theme.roundingFull
    color: Theme.surfaceContainer

    Behavior on implicitWidth { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "web_asset"
            color: Theme.secondary
            font.family: Theme.materialFont
            font.pixelSize: Theme.materialIconSize
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }

        Text {
            text: root.title
            color: Theme.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            width: Math.min(implicitWidth, 250)
            elide: Text.ElideRight
            maximumLineCount: 1
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }
    }
}
