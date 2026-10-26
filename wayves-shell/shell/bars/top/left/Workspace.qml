import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell.Hyprland

import qs.config
import qs.config.theme

RowLayout {
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignCenter
    spacing: ShellConfig.px(14)

    property var activeWorkspace: Hyprland.focusedWorkspace

    Workspaces {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }

    ActiveWindow {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }

    component Workspaces: RowLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: ShellConfig.px(8)

        Connections {
            target: Hyprland

            function onFocusedWorkspaceChanged() {
                workspaceRepeater.model = 0;
                activeWorkspace = Hyprland.focusedWorkspace;
                workspaceRepeater.model = Hyprland.workspaces;
            }
        }

        Repeater {
            id: workspaceRepeater
            model: Hyprland.workspaces

            delegate: Pane {
                Layout.alignment: Qt.AlignCenter
                horizontalPadding: ShellConfig.px(12 + (modelData.active ? 8 : 0))
                verticalPadding: ShellConfig.px(10)
                Layout.fillWidth: true

                background: Rectangle {
                    z: 1
                    Layout.alignment: Qt.AlignCenter

                    radius: ShellConfig.px(15)
                    color: modelData.active ? Colors.primary : Colors.on_surface

                    Text {
                        color: Colors.on_primary
                        anchors.centerIn: parent
                        font.pixelSize: ShellConfig.fontPx(12)
                        font.bold: true
                        text: modelData.id
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            if (!modelData.active)
                                modelData.activate();
                        }
                    }
                }
            }
        }
    }

    component ActiveWindow: RowLayout {
        id: activeWindowTitleRow
        spacing: 0
        property bool isActiveWindowInActiveWorkspace: Hyprland.activeToplevel && (Hyprland.activeToplevel.workspace.id === activeWorkspace.id)
        visible: isActiveWindowInActiveWorkspace
        Pane {
            clip: true
            Layout.alignment: Qt.AlignCenter
            horizontalPadding: ShellConfig.px(7)
            verticalPadding: ShellConfig.px(4)
            background: Rectangle {
                clip: true
                border.width: 1
                border.color: Colors.outline
                radius: ShellConfig.px(20)
                color: Colors.primary_container
            }

            Rectangle {
                id: textContainer
                implicitWidth: Math.min(childrenRect.width, ShellConfig.px(145))
                implicitHeight: childrenRect.height
                property bool hovered: false
                color: "transparent"
                Text {
                    font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                    id: text
                    color: Colors.on_primary_container
                    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                    onTextChanged: {
                        marqueeAnimation.stop();
                        x = 0;

                        if (textContainer.hovered && paintedWidth > textContainer.width)
                            marqueeAnimation.start();
                    }
                    wrapMode: Text.NoWrap
                    SequentialAnimation on x {
                        id: marqueeAnimation

                        running: textContainer.hovered && text.paintedWidth > textContainer.implicitWidth && text.text !== ""

                        loops: Animation.Infinite

                        PauseAnimation {
                            duration: 1200
                        }

                        NumberAnimation {
                            from: 0
                            to: -(text.paintedWidth - textContainer.width)
                            duration: Math.max(2000, (text.paintedWidth - textContainer.width) * 30)
                            easing.type: Easing.Linear
                        }

                        PauseAnimation {
                            duration: 1200
                        }

                        NumberAnimation {
                            from: -(text.paintedWidth - textContainer.width)
                            to: 0
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                HoverHandler {
                    onHoveredChanged: textContainer.hovered = hovered
                }
            }
        }
    }
}
