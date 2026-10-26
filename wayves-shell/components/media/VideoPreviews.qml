pragma Singleton

import QtQuick
import QtMultimedia
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

Singleton {
    id: root
    property var source: ""
    property var videoOutput: null
    property var position: 0
    property bool shouldPlay: true

    property var previewReady: ({})
    property var previewQueue: []
    property string wanted: ""

    function previewOf(path) {
        const slash = path.lastIndexOf("/");
        const name = path.substring(slash + 1);
        const dot = name.lastIndexOf(".");
        return path.substring(0, slash) + "/.previews/" + (dot === -1 ? name : name.substring(0, dot)) + ".mp4";
    }

    function preparePreviews(paths) {
        if (!ShellConfig.previewCopiesNeeded)
            return;
        for (const path of paths) {
            if (!previewReady[path] && previewQueue.indexOf(path) === -1 && previewJob.source !== path)
                previewQueue.push(path);
        }
        nextPreview();
    }

    function nextPreview() {
        if (previewJob.running || previewQueue.length === 0)
            return;
        previewJob.source = previewQueue.shift();
        previewJob.running = true;
    }

    Process {
        id: previewJob
        property string source: ""

        command: ["sh", "-c", `[ -f "$2" ] || { mkdir -p "$(dirname "$2")" && nice -n 19 ffmpeg -v error -y -i "$1" -an -vf "scale='min(1280,iw)':-2,fps=30" -c:v libx264 -preset veryfast -crf 26 -pix_fmt yuv420p -movflags +faststart "$2.part.mp4" && mv "$2.part.mp4" "$2"; }`, "sh", source, root.previewOf(source)]

        onExited: exitCode => {
            const done = source;
            source = "";
            if (exitCode === 0) {
                root.previewReady = Object.assign({}, root.previewReady, {
                    [done]: true
                });
                if (root.wanted === "file://" + done && root.shouldPlay)
                    root.changeVideo(root.wanted);
            }
            Qt.callLater(root.nextPreview);
        }
    }

    FolderListModel {
        id: videoFolder
        folder: "file://" + ShellConfig.wallpaperDirectory
        nameFilters: MediaFormats.videoFilters
        caseSensitive: false
        showDirs: false

        onStatusChanged: {
            if (status !== FolderListModel.Ready)
                return;
            const paths = [];
            for (let i = 0; i < count; i++)
                paths.push(get(i, "filePath"));
            root.preparePreviews(paths);
        }
    }

    property var players: ({})
    property var current: null
    readonly property bool playing: current !== null && current.playbackState === MediaPlayer.PlayingState

    MediaPlayer {}

    Component {
        id: playerComponent

        MediaPlayer {
            loops: MediaPlayer.Infinite
        }
    }

    function playerFor(path) {
        if (!players[path])
            players[path] = playerComponent.createObject(root, {
                source: "file://" + previewOf(path)
            });
        return players[path];
    }

    function play() {
        current?.play();
    }

    function pause() {
        current?.pause();
    }

    function stop() {
        if (!current)
            return;
        current.pause();
        current.videoOutput = null;
    }

    function setPosition(position) {
        root.position = position;
        if (current)
            current.position = position;
    }

    function changeVideo(newSource) {
        root.wanted = newSource;
        if (newSource == "")
            return;

        const path = newSource.toString().replace("file://", "");
        if (!root.previewReady[path]) {
            if (previewJob.source !== path)
                root.previewQueue = [path].concat(root.previewQueue.filter(p => p !== path));
            root.nextPreview();
            return;
        }

        const next = playerFor(path);
        if (current && current !== next) {
            current.pause();
            current.videoOutput = null;
        }
        current = next;
        root.source = next.source;
        next.videoOutput = root.videoOutput;
        next.position = 0;
        if (root.shouldPlay)
            next.play();
    }
}
