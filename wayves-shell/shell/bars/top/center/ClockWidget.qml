import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Services.Mpris

import qs.config
import qs.config.theme
import qs.services

RowLayout {
    id: centerBarWidget
    spacing: ShellConfig.px(12)
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    property var lastActivePlayer: null
    readonly property var players: Mpris.players.values

    function updatePlayer() {
        if (players.length === 0) {
            lastActivePlayer = null;
            return;
        }

        const best = PlayerRanking.pick(players, lastActivePlayer);
        lastActivePlayer = best?.playbackState === MprisPlaybackState.Playing ? best : null;
    }

    function formatTime(ms) {
        if (ms <= 0 || isNaN(ms))
            return "0:00";

        let totalSeconds = Math.floor(ms);
        let minutes = Math.floor(totalSeconds / 60);
        let seconds = totalSeconds % 60;
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            updatePlayer();
        }
    }
    Instantiator {
        id: instantiator
        model: Mpris.players
        onObjectAdded: {
            updatePlayer();
        }
        onObjectRemoved: {
            updatePlayer();
        }

        delegate: Item {
            Connections {
                target: modelData
                function onTrackChanged() {
                    updatePlayer();
                }

                function onPlaybackStateChanged() {
                    updatePlayer();
                }
            }
        }
    }

    Rectangle {
        id: rect
        width: ShellConfig.px(35)
        height: ShellConfig.px(35)

        clip: true
        color: "transparent"

        visible: lastActivePlayer ? true : false

        Item {
            width: rect.width
            height: rect.height
            Rectangle {
                id: maskShape
                anchors.fill: parent
                radius: ShellConfig.px(8)

                visible: false
            }
            Rectangle {
                anchors.fill: parent
                radius: maskShape.radius
                border.width: .5
                color: "transparent"
                border.color: '#3bffffff'
                Image {
                    id: imageArt

                    anchors.fill: parent
                    anchors.margins: ShellConfig.px(2)
                    fillMode: Image.PreserveAspectCrop

                    sourceSize.width: parent.width
                    sourceSize.height: parent.height

                    source: lastActivePlayer ? lastActivePlayer.trackArtUrl : ""
                    mipmap: true
                    smooth: true
                    visible: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: maskShape
                    }
                }
            }
        }
    }

    Text {
        font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "dd MMM yyyy | hh:mm AP")
        color: Colors.on_surface
    }
}
