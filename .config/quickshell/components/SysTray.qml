import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import ".."

Rectangle {
    id: root

    visible: SystemTray.items.count > 0
    implicitWidth: visible ? row.width + Theme.pillPadding * 2 : 0
    implicitHeight: Theme.pillHeight
    radius: Theme.roundingFull
    color: Theme.surfaceContainer

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items

            Item {
                required property SystemTrayItem modelData
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: modelData.icon ?? ""
                    sourceSize.width: 18
                    sourceSize.height: 18
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event.button === Qt.RightButton)
                            modelData.secondaryActivate();
                        else
                            modelData.activate();
                    }
                }
            }
        }
    }
}
