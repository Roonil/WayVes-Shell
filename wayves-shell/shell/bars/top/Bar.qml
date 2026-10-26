import QtQuick

import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland

import qs.config
import qs.components.notch
import qs.config.theme
import qs.enums
import qs.shell.bars.top.left
import qs.shell.bars.top.center
import qs.shell.bars.top.right
import qs.shell.bars.top.right.systemTray

ShellRoot {
    id: shellRoot
    property var visible: true
    signal showingWallpapers(bool isShowingWallpapers)
    property var configObject: undefined

    property int exclusiveZone: ShellConfig.px(configObject?.exclusiveZone ?? 40)

    readonly property var behavior: configObject?.behavior
    readonly property bool changeWhenWindowOpen: behavior?.changeWhenWindowOpen ?? true

    PanelWindow {
        id: root
        readonly property bool currentWorkspaceHasWindows: (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) > 0

        property real radius: ShellConfig.px(28)
        readonly property bool windowOpenStyle: shellRoot.changeWhenWindowOpen && currentWorkspaceHasWindows
        function styleValue(key, fallback) {
            return (windowOpenStyle ? shellRoot.behavior?.windowOpen?.[key] : undefined) ?? shellRoot.behavior?.default?.[key] ?? fallback;
        }
        readonly property string attach: {
            const value = styleValue("attach", windowOpenStyle ? "edges" : "none");
            return ["none", "top", "edges"].includes(value) ? value : "none";
        }
        readonly property real topMargin: attach === "none" ? ShellConfig.px(styleValue("topMargin", 10)) : 0
        readonly property real sideMargin: attach === "edges" ? 0 : ShellConfig.px(styleValue("sideMargin", 12))

        Behavior on radius {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuint
            }
        }

        anchors.top: true
        anchors.left: true
        anchors.right: true

        property bool showWallpapers: false
        onShowWallpapersChanged: showingWallpapers(showWallpapers)

        exclusiveZone: shellRoot.exclusiveZone
        exclusionMode: ExclusionMode.Auto
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "top-bar"
        implicitHeight: Quickshell.screens[0].height

        WlrLayershell.keyboardFocus: root.showWallpapers && centerBar.expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

        color: "transparent"

        property var extraRects: []

        mask: rootRegion

        IpcHandler {
            target: "showWallpapers"
            function toggle() {
                root.showWallpapers = !root.showWallpapers;
                centerBar.hovered = root.showWallpapers;
            }

            function on() {
                if (root.showWallpapers)
                    return;

                root.showWallpapers = true;
                centerBar.hovered = true;
            }
            function off() {
                if (!root.showWallpapers)
                    return;

                root.showWallpapers = false;
                centerBar.hovered = false;
            }
        }

        Region {
            id: rootRegion

            Region {
                item: workspaceNotch
            }

            Region {
                item: centerBar
            }

            Region {
                item: rightBar
            }

            Region {
                item: systemTrayPanel
            }
        }

        RowLayout {
            id: bar

            anchors.right: parent.right
            anchors.horizontalCenter: parent.horizontalCenter

            y: root.topMargin

            Behavior on y {
                NumberAnimation {
                    id: offsetAnimation
                    duration: 300
                    easing.type: Easing.OutQuint
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft

                RowLayout {
                    anchors.left: parent.left

                    Item {
                        visible: !root.showWallpapers

                        Layout.preferredWidth: childrenRect.width
                        Layout.fillHeight: true

                        transform: Translate {
                            x: root.sideMargin
                        }

                        Notch {
                            id: workspaceNotch

                            anchors.left: parent.left

                            configObject: shellRoot.configObject?.left?.notch

                            direction: root.attach === "none" ? Directions.None : root.attach === "edges" ? Directions.Down | Directions.Right : Directions.Down

                            alwaysShowHeader: true

                            headerContent: Workspace {}
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter

                Notch {
                    id: centerBar

                    anchors.horizontalCenter: parent.horizontalCenter

                    direction: root.attach === "none" ? Directions.None : Directions.Down
                    configObject: shellRoot.configObject?.center?.notch

                    onExpandedChanged: {
                        root.mask = (expanded) ? null : rootRegion;
                        centerBar.dropShadow.applyToShape = root.showWallpapers || (centerBar.configObject?.dropShadow?.applyToShape ?? true);
                    }
                    onHoveredChanged: {
                        if (!hovered) {
                            root.showWallpapers = false;
                        }
                    }

                    headerContent: ClockWidget {}

                    panelContent: ColumnLayout {
                        MediaWidget {
                            visible: !root.showWallpapers
                            Layout.fillHeight: true
                            sideNotchConfig: shellRoot.configObject?.center?.notch?.sideNotch
                            bottomNotchConfig: shellRoot.configObject?.center?.notch?.bottomNotch
                            entered: centerBar.expanded && (!root.showWallpapers)
                            topRightRadius: centerBar.shapeConfig.topRightRadius
                            bottomRightRadius: centerBar.shapeConfig.bottomRightRadius
                        }

                        Loader {
                            asynchronous: true
                            visible: root.showWallpapers

                            active: visible
                            width: childrenRect.width
                            height: childrenRect.height
                            sourceComponent: WallpaperPicker {
                                visible: root.showWallpapers
                                entered: centerBar.expanded && root.showWallpapers
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.right: parent.right
                    spacing: ShellConfig.px(20)
                    visible: !root.showWallpapers

                    Item {
                        Layout.preferredWidth: childrenRect.width
                        Layout.fillHeight: true
                        Notch {
                            id: systemTrayPanel
                            property Component activePanel: null

                            visible: !root.showWallpapers
                            anchors.right: parent.right
                            configObject: shellRoot.configObject?.systemTray?.notch

                            notchConfig.minimumHeaderHeight: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.minimumHeaderHeight ?? -1) : 0
                            notchConfig.minimumHeaderWidth: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.minimumHeaderWidth ?? -1) : 0

                            notchConfig.headerPadding: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.headerPadding) : 0
                            notchConfig.headerTopPadding: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.headerTopPadding) : 0
                            notchConfig.headerBottomPadding: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.headerBottomPadding) : 0
                            notchConfig.headerLeftPadding: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.headerLeftPadding) : 0
                            notchConfig.headerRightPadding: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.headerRightPadding) : 0

                            notchConfig.headerHorizontalPadding: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.headerHorizontalPadding) : 0
                            notchConfig.headerVerticalPadding: SystemTray.items.values.length > 0 ? ShellConfig.pxOpt(shellRoot.configObject?.systemTray?.notch?.headerVerticalPadding) : 0

                            direction: root.attach === "none" ? Directions.None : Directions.Down

                            alwaysShowHeader: true
                            checkParentBottomLeftOverflow: true

                            onExpandedChanged: {
                                root.mask = expanded ? null : rootRegion;
                            }

                            headerContent: SystemTrayCard {
                                configObject: shellRoot.configObject?.systemTray?.sideNotch
                                onRequestPanelChange: newPanel => {
                                    systemTrayPanel.activePanel = newPanel;
                                }
                            }

                            panelContent: activePanel
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Item {
                        transform: Translate {
                            x: -root.sideMargin
                        }
                        Layout.preferredWidth: childrenRect.width
                        Layout.fillHeight: true

                        Notch {
                            id: rightBar

                            visible: !root.showWallpapers
                            configObject: shellRoot.configObject?.right?.notch

                            alwaysShowHeader: true
                            preloadContent: true
                            anchors.right: parent.right

                            direction: root.attach === "none" ? Directions.None : root.attach === "edges" ? Directions.Down | Directions.Left : Directions.Down

                            property int selectedIndex: 0

                            property bool loaderActive: true

                            onExpandedChanged: {
                                root.mask = expanded ? null : rootRegion;
                            }

                            panelContent: ColumnLayout {

                                WifiCard {
                                    visible: rightBar.selectedIndex === 0
                                    shown: rightBar.expanded && visible
                                }

                                BluetoothCard {
                                    visible: rightBar.selectedIndex === 1
                                    shown: rightBar.expanded && visible
                                }
                                SoundCard {
                                    configObject: shellRoot.configObject?.right?.sideNotch
                                    visible: rightBar.selectedIndex === 2
                                }
                            }

                            headerContent: Controls {
                                onRequestPanelChange: index => {
                                    rightBar.selectedIndex = index;
                                    rightBar.hovered = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
