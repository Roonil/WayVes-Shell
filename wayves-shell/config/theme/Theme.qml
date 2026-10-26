pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

import qs.config.theme
import qs.services

Singleton {
    id: root

    property string wallpaperSource: jsonAdapter.wallpaperSource

    property bool isDark: jsonAdapter.isDark

    readonly property string historyPath: Quickshell.shellPath("persist/wallpaper.json")
    property string thumbnailSource: ""

    property bool loaded: false

    onThumbnailSourceChanged: {
        if (thumbnailSource === "")
            return;

        Quickshell.execDetached(["matugen", "image", root.thumbnailSource, "-m", root.isDark ? "dark" : "light", "--source-color-index", "0"]);
    }

    onWallpaperSourceChanged: {
        if (!root.loaded || jsonAdapter.wallpaperIsVideo)
            return;

        thumbnailSource = "";

        Quickshell.execDetached(["matugen", "image", jsonAdapter.wallpaperSource.split("file://")[1], "-m", jsonAdapter.isDark ? "dark" : "light", "--source-color-index", "0"]);
    }

    onIsDarkChanged: {
        if (!root.loaded)
            return;

        if (thumbnailSource != "") {
            Quickshell.execDetached(["matugen", "image", root.thumbnailSource, "-m", root.isDark ? "dark" : "light", "--source-color-index", "0"]);
            return;
        }

        Quickshell.execDetached(["matugen", "image", jsonAdapter.wallpaperSource.split("file://")[1], "-m", root.isDark ? "dark" : "light", "--source-color-index", "0"]);
    }

    ThumbnailExtractor {
        id: extractor

        onExtractionFinished: thumbnailPath => {
            root.thumbnailSource = thumbnailPath;
        }

        onExtractionFailed: videoPath => {}
    }

    FileView {
        id: historyFile
        path: historyPath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        adapter: JsonAdapter {
            id: jsonAdapter
            property string wallpaperSource: ""
            property bool isDark: true
            readonly property bool wallpaperIsVideo: MediaFormats.isVideo(wallpaperSource)
        }

        onLoaded: {
            root.loaded = true;
            if (jsonAdapter.wallpaperIsVideo)
                extractor.extractThumbnailForVideoIfAbsent(jsonAdapter.wallpaperSource);
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                jsonAdapter.wallpaperSource = "";
                jsonAdapter.isDark = true;
                historyFile.writeAdapter();
            }
        }
    }

    function toRgbaString(color) {
        let r = Math.round(color.r * 255);
        let g = Math.round(color.g * 255);
        let b = Math.round(color.b * 255);
        let a = color.a;

        return `rgba(${r}, ${g}, ${b}, ${a})`;
    }

    function updateWayVesColors(color, propertyName, pipeName) {
        Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo '${propertyName}=${color}' > /tmp/WayVes/${pipeName}`]);
    }

    function updateThemeMode(newIsDark) {
        jsonAdapter.isDark = newIsDark;
        root.isDark = newIsDark;
        historyFile.writeAdapter();

        if (jsonAdapter.wallpaperIsVideo) {
            extractor.extractThumbnailForVideoIfAbsent(wallpaperSource);
            return;
        }

    }

    function updateWallpaper(path) {
        jsonAdapter.wallpaperSource = "file://" + path;
        if (jsonAdapter.wallpaperIsVideo) {
            root.thumbnailSource = "";
            extractor.extractThumbnailForVideoIfAbsent(jsonAdapter.wallpaperSource);
        }

        historyFile.writeAdapter();
    }
}
