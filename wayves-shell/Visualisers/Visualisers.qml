pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.config

Item {

    component DummyItem: Item {
        property bool active: false
        property bool isActive: false
        property var type
        property var purpose
    }

    component NCS: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        visibilityChangeCommand: "WayVes -c ncs -v {{v}}"
        geometryChangeCommand: "WayVes -c ncs -w {{w}} -h {{h}}"
        socketPath: "/tmp/WayVes/ncs.sock"
    }

    component Card: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        visibilityChangeCommand: "WayVes -c linear_pill -v {{v}}"
        geometryChangeCommand: "WayVes -c linear_pill -w {{w}} -h {{h}}"
        socketPath: "/tmp/WayVes/pill.sock"
    }

    component TopWaves: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        visibilityChangeCommand: "WayVes -c waves -v {{v}}"
        geometryChangeCommand: "WayVes -c waves -w {{w}} -h 112"
        socketPath: "/tmp/WayVes/waves.sock"
    }

    component BottomWaves: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        geometryChangeCommand: "WayVes -c waves_caps -w {{w}} -h {{h}}"
        visibilityChangeCommand: "WayVes -c waves_caps -v {{v}}"

        socketPath: "/tmp/WayVes/waves_caps.sock"
    }

    component PasswordMask: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        visibilityChangeCommand: "WayVes -c linear_password_mask -v {{v}}"
        geometryChangeCommand: "WayVes -c linear_password_mask -w {{w}} -h {{h}}"
        socketPath: "/tmp/WayVes/password_mask.sock"
    }

    component ThemeButton: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        visibilityChangeCommand: "WayVes -c angular_theme_button -v {{v}}"
        geometryChangeCommand: "WayVes -c angular_theme_button -w {{w}} -h {{h}}"
        socketPath: "/tmp/WayVes/theme_button.sock"
    }

    component Logo: DMABufSurface {
        fps: 60
        visibilityChangeCommand: "WayVes -c logo -v {{v}}"
        socketPath: "/tmp/WayVes/logo.sock"
    }

    component WallpaperBackground: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        visibilityChangeCommand: "sleep 0.1; WayVes -c ncs_wallpaper -v {{v}}"
        geometryChangeCommand: "WayVes -c ncs_wallpaper -w {{w}} -h {{h}}"
        socketPath: "/tmp/WayVes/ncs_wallpaper.sock"
    }

    component WallpaperPickerBackground: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        visibilityChangeCommand: "WayVes -c ncs_card -v {{v}}"
        geometryChangeCommand: "WayVes -c ncs_card -w {{w}} -h {{h}}"
        socketPath: "/tmp/WayVes/ncs_card.sock"
    }

    component LockScreenBackground: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        visibilityChangeCommand: "WayVes -c ncs_xmb -v {{v}}"
        geometryChangeCommand: "WayVes -c ncs_xmb -w {{w}} -h {{h}}"
        socketPath: "/tmp/WayVes/ncs_xmb.sock"
    }

    component AudioOverview: DMABufSurface {
        fps: ShellConfig.cappedFps(60)
        geometryChangeCommand: "WayVes -c audio_tracker -w {{w}} -h {{h}}"
        visibilityChangeCommand: "WayVes -c audio_tracker -v {{v}}"
        socketPath: "/tmp/WayVes/audioTracker.sock"
    }

    component Hud: DMABufSurface {
        property var type: undefined
        fps: type === "surface" && ShellConfig.hudSurfaceFps > 0 ? ShellConfig.hudSurfaceFps : ShellConfig.cappedFps(type === "waves" ? 60 : 30)
        geometryChangeCommand: `WayVes -c hud_${type} -w {{w}} -h {{h}}`
        visibilityChangeCommand: `WayVes -c hud_${type} -v {{v}}`
        socketPath: `/tmp/WayVes/hud_${type}.sock`
    }

    component Usage: DMABufSurface {
        fps: ShellConfig.usageFps > 0 ? ShellConfig.usageFps : ShellConfig.cappedFps(60)
        property var purpose: undefined
        visibilityChangeCommand: `WayVes -c ${purpose} -v {{v}}`
        geometryChangeCommand: `WayVes -c ${purpose} -w {{w}} -h {{h}}`
        socketPath: `/tmp/WayVes/${purpose}.sock`
    }

    component Dock: DMABufSurface {
        fps: ShellConfig.dockFps > 0 ? ShellConfig.dockFps : ShellConfig.cappedFps(25)
        visibilityChangeCommand: "sleep 0.1; WayVes -c dock -v {{v}}"
        geometryChangeCommand: "WayVes -c dock -w {{w}} -h {{h}}"
        socketPath: "/tmp/WayVes/dock.sock"
    }

    component AppIndicator: DMABufSurface {
        property bool isActive: false
        fps: ShellConfig.cappedFps(25)
        visibilityChangeCommand: (isActive ? "WayVes -c selector_active -v {{v}}" : "WayVes -c selector -v {{v}}")
        socketPath: isActive ? "/tmp/WayVes/selector_active.sock" : "/tmp/WayVes/selector.sock"
    }

    component DummyRedraw: Item {
        id: dummy
        property bool active: false
        property real fps: ShellConfig.cappedFps(25)

        Rectangle {
            id: trace
            anchors.fill: parent
            color: "#02ffffff"
        }

        Timer {
            interval: 1000 / dummy.fps
            running: dummy.visible
            repeat: true
            onTriggered: trace.opacity = trace.opacity === 1 ? 0.99 : 1
        }
    }
}
