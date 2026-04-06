import QtQuick
import ".."

// Material Symbols Rounded icon (matching Caelestia)
Text {
    property alias iconColor: root.color

    id: root
    color: Theme.secondary
    font.family: Theme.materialFont
    font.pixelSize: Theme.materialIconSize
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
