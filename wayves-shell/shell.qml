import QtQuick

import Quickshell
import Quickshell.Io

import Quickshell.Services.SystemTray
import Quickshell.Wayland

import qs.shell.bars.top
import qs.shell.bars.side
import qs.shell.dock
import qs.shell.background

import qs.shell.power_menu
import qs.components.media
import qs.config

PanelWindow {
    id: root
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore
    property bool isDim: false
    color: isDim ? '#91111111' : "transparent"
    property real opacity: isDim ? .0 : 1.0

    onIsDimChanged: opacity = isDim ? 0 : 1

    mask: Region {
        item: Rectangle {
            width: 0
            height: 0
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    implicitWidth: Quickshell.screens[0].width
    implicitHeight: Quickshell.screens[0].height

    property var configObject: ShellConfig.configObject

    Component.onCompleted: {
        let var1 = VideoPreviews.source;
    }

    Dock {
        opacity: root.opacity
        configObject: root.configObject?.dock
    }

    SideBar {
        configObject: root.configObject?.bars?.side
    }

    Bar {
        configObject: root.configObject?.bars?.top
        onShowingWallpapers: visibility => root.opacity = visibility ? 0 : 1
    }

    PowerMenu {
        configObject: root.configObject?.lockscreen
        onToggled: toggleValue => Qt.callLater(() => {
                root.isDim = toggleValue;
            })
    }

    Background {}
}

