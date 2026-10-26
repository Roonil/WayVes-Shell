pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property var ready: ({})
    property var queue: []

    function thumbnailOf(path) {
        const slash = path.lastIndexOf("/");
        const name = path.substring(slash + 1);
        const dot = name.lastIndexOf(".");
        return path.substring(0, slash) + "/.thumbnails/" + (dot === -1 ? name : name.substring(0, dot)) + ".jpg";
    }


    function ensure(paths) {
        for (const path of paths) {
            if (ready[path] === undefined && queue.indexOf(path) === -1 && job.source !== path)
                queue.push(path);
        }
        next();
    }

    function next() {
        if (job.running || queue.length === 0)
            return;
        job.source = queue.shift();
        job.running = true;
    }

    Process {
        id: job
        property string source: ""

        command: ["sh", "-c", `[ -f "$2" ] || { mkdir -p "$(dirname "$2")" && ffmpeg -v error -y -i "$1" -vframes 1 "$2.part.jpg" && mv "$2.part.jpg" "$2"; }`, "sh", source, root.thumbnailOf(source)]

        onExited: exitCode => {
            const done = source;
            source = "";
            if (exitCode === 0) {
                const updated = Object.assign({}, root.ready);
                updated[done] = root.thumbnailOf(done);
                root.ready = updated;
            }
            Qt.callLater(root.next);
        }
    }

    FolderListModel {
        folder: "file://" + ShellConfig.wallpaperDirectory
        nameFilters: MediaFormats.videoFilters
        caseSensitive: false
        showDirs: false

        function ensureAll() {
            if (status !== FolderListModel.Ready)
                return;
            const paths = [];
            for (let i = 0; i < count; i++)
                paths.push(get(i, "filePath"));
            root.ensure(paths);
        }

        onStatusChanged: ensureAll()
        onCountChanged: ensureAll()
    }
}
