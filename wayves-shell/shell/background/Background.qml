import QtQuick
import QtMultimedia

import Quickshell
import qs.components.media
import qs.config
import qs.config.theme
import qs.services
import Quickshell.Wayland

PanelWindow {
    id: root
    WlrLayershell.layer: WlrLayer.Background
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    readonly property bool isVideo: MediaFormats.isVideo(Theme.wallpaperSource)
    readonly property bool playsVideo: isVideo && ShellConfig.videoWallpaper !== "still"
    readonly property string videoPath: Theme.wallpaperSource.replace("file://", "")
    readonly property string videoSource: {
        if (!playsVideo)
            return "";
        if (ShellConfig.videoWallpaper === "preview" && VideoPreviews.previewReady[videoPath])
            return "file://" + VideoPreviews.previewOf(videoPath);
        return Theme.wallpaperSource;
    }
    readonly property string imageSource: {
        if (!isVideo)
            return Theme.wallpaperSource;
        if (playsVideo)
            return "";
        const thumbnail = Thumbnails.ready[videoPath];
        return thumbnail === undefined ? "" : "file://" + thumbnail;
    }

    Image {
        id: bg
        anchors.fill: parent
        visible: !root.playsVideo
        source: root.imageSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        layer.enabled: true

        Behavior on source {
            SequentialAnimation {
                NumberAnimation {
                    target: bg
                    property: "opacity"
                    to: 0
                    duration: 400
                }
                PropertyAction {
                    target: bg
                    property: "source"
                }
                NumberAnimation {
                    target: bg
                    property: "opacity"
                    to: 1
                    duration: 400
                }
            }
        }
    }

    Component {
        id: videoPlayerComponent

        Item {
            anchors.fill: parent
            MediaPlayer {
                id: player
                source: root.videoSource
                videoOutput: vOutput

                loops: MediaPlayer.Infinite
                autoPlay: true

                Behavior on source {
                    SequentialAnimation {
                        NumberAnimation {
                            target: vOutput
                            property: "opacity"
                            to: 0
                            duration: 400
                        }
                        PropertyAction {
                            target: player
                            property: "source"
                        }
                        ScriptAction {
                            script: player.play()
                        }
                        NumberAnimation {
                            target: vOutput
                            property: "opacity"
                            to: 1
                            duration: 400
                        }
                    }
                }

                Component.onCompleted: if (root.playsVideo)
                    player.play()
                Component.onDestruction: player.stop()
            }

            VideoOutput {
                id: vOutput
                fillMode: VideoOutput.PreserveAspectCrop

                anchors.fill: parent
            }
        }
    }

    Loader {
        sourceComponent: videoPlayerComponent
        asynchronous: true
        anchors.fill: parent
        active: root.playsVideo
    }
}
