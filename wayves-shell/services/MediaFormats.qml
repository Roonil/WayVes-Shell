pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property list<string> imageSuffixes: ["jpg", "jpeg", "png", "webp"]
    readonly property list<string> videoSuffixes: ["mp4", "mkv", "webm", "mov"]

    readonly property list<string> imageFilters: imageSuffixes.map(suffix => "*." + suffix)
    readonly property list<string> videoFilters: videoSuffixes.map(suffix => "*." + suffix)

    function isVideo(path) {
        const name = String(path ?? "");
        const dot = name.lastIndexOf(".");
        return videoSuffixes.includes((dot === -1 ? name : name.substring(dot + 1)).toLowerCase());
    }
}
