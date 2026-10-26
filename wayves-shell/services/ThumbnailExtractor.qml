import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal extractionFinished(string thumbnailPath)
    signal extractionFailed(string videoPath)

    function extractThumbnailForVideoIfAbsent(wallpaperPath) {
        const videoPath = wallpaperPath.toString().replace("file://", "");
        if (videoPath.lastIndexOf("/") === -1) {
            console.error("ThumbnailExtractor: Invalid file path (no directory structure found).");
            extractionFailed(wallpaperPath);
            return;
        }

        if (job.running) {
            job.pending = videoPath;
            return;
        }
        job.videoPath = videoPath;
        job.running = true;
    }

    Process {
        id: job
        property string videoPath: ""
        property string pending: ""
        readonly property string thumbnailPath: Thumbnails.thumbnailOf(videoPath)

        command: ["sh", "-c", `[ -f "$2" ] || { mkdir -p "$(dirname "$2")" && ffmpeg -v error -y -i "$1" -vframes 1 "$2.part.jpg" && mv "$2.part.jpg" "$2"; }`, "sh", videoPath, thumbnailPath]

        onExited: exitCode => {
            if (exitCode === 0)
                root.extractionFinished(thumbnailPath);
            else
                root.extractionFailed("file://" + videoPath);

            if (pending !== "") {
                const next = pending;
                pending = "";
                Qt.callLater(() => root.extractThumbnailForVideoIfAbsent(next));
            }
        }
    }
}
