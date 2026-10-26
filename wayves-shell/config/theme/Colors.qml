pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config.theme

QtObject {
    id: root
    readonly property bool isDark: Theme.isDark
    property bool colorsLoaded: false

    property FileView themeFile: FileView {
        id: fileView
        path: Quickshell.shellDir + "/persist/Colors.json"
        watchChanges: true

        onFileChanged: reload()

        onLoaded: {
            root.colorsLoaded = true;
            root.pushWhenReady();
        }

        adapter: JsonAdapter {
            id: jsonAdapter

            property string source: ""
            property string primary: ""
            property string on_primary: ""
            property string primary_container: ""
            property string on_primary_container: ""
            property string secondary: ""
            property string tertiary: ""
            property string surface: ""
            property string on_surface: ""
            property string surface_container: ""
            property string outline: ""
            property string on_disabled: ""
            property string surface_disabled: ""

            property string source_rgba: ""
            property string primary_rgba: ""
            property string on_primary_rgba: ""
            property string primary_container_rgba: ""
            property string on_primary_container_rgba: ""
            property string secondary_rgba: ""
            property string tertiary_rgba: ""
            property string surface_rgba: ""
            property string on_surface_rgba: ""
            property string surface_container_rgba: ""
            property string outline_rgba: ""
            property string on_disabled_rgba: ""
            property string surface_disabled_rgba: ""

            function rgbaString() {
                return "sourceColor=" + source_rgba + "\n" + "primary=" + primary_rgba + "\n" + "onPrimary=" + on_primary_rgba + "\n" + "primaryContainer=" + primary_container_rgba + "\n" + "onPrimaryContainer=" + on_primary_container_rgba + "\n" + "secondary=" + secondary_rgba + "\n" + "tertiary=" + tertiary_rgba + "\n" + "surface=" + surface_rgba + "\n" + "onSurface=" + on_surface_rgba + "\n" + "surfaceContainer=" + surface_container_rgba + "\n" + "outline=" + outline_rgba + "\n" + "onDisabled=" + on_disabled_rgba + "\n" + "surfaceDisabled=" + surface_disabled_rgba + "\n" + "isDarkMode=" + root.isDark;
            }
        }
    }

    property Connections themeLoaded: Connections {
        target: Theme
        function onLoadedChanged() {
            root.pushWhenReady();
        }
    }

    function pushWhenReady() {
        if (Theme.loaded && colorsLoaded && jsonAdapter.primary !== "")
            pushWayVesData();
    }

    property color source: jsonAdapter.source || "black"
    property color primary: jsonAdapter.primary || "black"
    property color on_primary: jsonAdapter.on_primary || "black"
    property color primary_container: jsonAdapter.primary_container || "black"
    property color on_primary_container: jsonAdapter.on_primary_container || "black"
    property color secondary: jsonAdapter.secondary || "black"
    property color tertiary: jsonAdapter.tertiary || "black"
    property color surface: jsonAdapter.surface || "black"
    property color on_surface: jsonAdapter.on_surface || "black"
    property color surface_container: jsonAdapter.surface_container || "black"
    property color outline: jsonAdapter.outline || "black"

    property color disabled: root.outline
    property color on_disabled: jsonAdapter.on_disabled || "black"
    property color surface_disabled: jsonAdapter.surface_disabled || "black"

    readonly property real animationDuration: 300

    Behavior on source {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on primary {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on on_primary {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on primary_container {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on on_primary_container {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on secondary {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on tertiary {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on surface {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on on_surface {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on surface_container {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on outline {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on disabled {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on on_disabled {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on surface_disabled {
        ColorAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }

    function pushWayVesData() {
        var colors = fileView.adapter.rgbaString();

        updateWayVesColors(colors, "ncs");
        updateWayVesColors(colors, "ncs_xmb");
        updateWayVesColors(colors, "linear_pill");
        updateWayVesColors(colors, "waves_caps");
        updateWayVesColors(colors, "waves");
        updateWayVesColors(colors, "audio_tracker");
        updateWayVesColors(colors, "hud_waves");
        updateWayVesColors(colors, "hud_outer_ring");
        updateWayVesColors(colors, "hud_surface");
        updateWayVesColors(colors, "dock");
        updateWayVesColors(colors, "cpu_usage");
        updateWayVesColors(colors, "gpu_usage");
        updateWayVesColors(colors, "memory_usage");
        updateWayVesColors(colors, "gpu_temp");
        updateWayVesColors(colors, "cpu_temp");
        updateWayVesColors(colors.replace(/\nisDarkMode=.*$/, ""), "angular_theme_button");
    }

    function updateWayVesColors(data, pipeName) {
        Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo '${data}' > /tmp/WayVes/${pipeName}`]);
    }
}
