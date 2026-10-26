pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var configObject: undefined

    readonly property string wallpaperDirectory: {
        const directory = configObject?.wallpapers?.directory ?? "~/Pictures/Wallpapers";
        const expanded = directory.startsWith("~") ? Quickshell.env("HOME") + directory.substring(1) : directory;
        return expanded.replace(/\/+$/, "");
    }

    readonly property var performance: configObject?.performance ?? ({})
    readonly property bool potato: performance.potato ?? false
    readonly property int visualiserFps: Math.round(performance.visualiserFps ?? (potato ? 10 : 0))
    readonly property int usageFps: Math.round(performance.usageFps ?? (potato ? 2 : 0))
    readonly property int dockFps: Math.round(performance.dockFps ?? (potato ? 1 : 0))
    readonly property int hudSurfaceFps: Math.round(performance.hudSurfaceFps ?? (potato ? 1 : 0))
    readonly property string videoWallpaper: performance.videoWallpaper ?? (potato ? "preview" : "original")
    readonly property bool pickerVideoPreviews: performance.pickerVideoPreviews ?? !potato
    readonly property bool previewCopiesNeeded: pickerVideoPreviews || videoWallpaper === "preview"

    readonly property var scale: configObject?.scale ?? ({})
    readonly property real sizeScale: scale.size ?? 1
    readonly property real fontScale: scale.font ?? 1

    readonly property real defaultPointSize: Qt.application.font.pointSize > 0 ? Qt.application.font.pointSize : 12

    function px(value) {
        return Math.round(value * sizeScale);
    }

    function pxOpt(value) {
        return typeof value === "number" && value >= 0 ? px(value) : value;
    }

    function fontPx(value) {
        return Math.max(1, Math.round(value * fontScale));
    }

    function cappedFps(fps) {
        return visualiserFps > 0 ? Math.min(fps, visualiserFps) : fps;
    }

    FileView {
        id: configFile
        path: Quickshell.shellDir + "/Properties/Properties.json"
        blockLoading: true

        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.configObject = JSON.parse(configFile.text());
            } catch (e) {
                console.error("Failed to parse config JSON:", e.message);
            }
        }
    }
}
