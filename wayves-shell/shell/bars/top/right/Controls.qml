import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Widgets

import qs.config
import qs.config.theme

Item {
    id: root

    signal requestPanelChange(int index)

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    IconButton {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        onRequestPanelChange: index => {
            root.requestPanelChange(index);
        }
    }

    component IconButton: Pane {
        id: root
        signal requestPanelChange(int index)

        property real size: ShellConfig.px(20)

        property list<string> images: ["network-wireless-signal-good-symbolic", "bluetooth-symbolic", "audio-volume-high-symbolic"]

        background: Rectangle {
            radius: ShellConfig.px(20)
            color: 'transparent'
        }

        padding: ShellConfig.px(2)

        RowLayout {
            id: row
            spacing: ShellConfig.px(20)

            anchors.centerIn: parent
            Repeater {
                model: root.images

                Rectangle {
                    Layout.alignment: Qt.AlignCenter
                    radius: root.size * 2
                    implicitWidth: root.size
                    implicitHeight: root.size
                    color: 'transparent'
                    IconImage {
                        id: icon
                        source: Quickshell.iconPath(modelData)
                        width: root.size
                        height: root.size

                        mipmap: true

                        backer.sourceSize.width: 25
                        backer.sourceSize.height: 25
                    }
                    ColorOverlay {
                        anchors.fill: icon
                        source: icon
                        color: Colors.on_surface
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor

                        onHoveredChanged: {
                            if (hovered)
                                root.requestPanelChange(index);
                        }
                    }
                }
            }
        }
    }
}
