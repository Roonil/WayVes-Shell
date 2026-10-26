import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes

import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Services.Mpris

import qs.config
import qs.components.controls
import qs.components.notch
import qs.config.theme
import qs.services
import qs.Visualisers
import qs.enums

ColumnLayout {
    id: root
    Material.theme: Colors.isDark ? Material.Dark : Material.Light
    Material.accent: Colors.primary

    property real topRightRadius: 0
    property real bottomRightRadius: 0
    readonly property real topRightFlare: Math.max(-topRightRadius, 0)

    property var rootWindow: null
    property var lastActivePlayer: null
    property var sideNotchConfig: null
    property var bottomNotchConfig: null
    spacing: 0

    readonly property var players: Mpris.players.values
    property bool entered: false

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            updatePlayer();
        }
    }

    function updatePlayer() {
        if (players.length === 0) {
            lastActivePlayer = null;
            return;
        }

        lastActivePlayer = PlayerRanking.pick(players, lastActivePlayer) ?? players[0];
    }

    function formatTime(ms) {
        if (ms <= 0 || isNaN(ms))
            return "0:00";

        let totalSeconds = Math.floor(ms);
        let minutes = Math.floor(totalSeconds / 60);
        let seconds = totalSeconds % 60;
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height

        Item {
            transform: Translate {
                y: ShellConfig.px(30)
            }

            PlayerSelector {
                visible: Mpris.players.values.length > 1
                anchors.right: parent.right
                configObject: root.sideNotchConfig
            }
        }

        Item {
            id: sourceContainer
            z: -1
            anchors.fill: parent
            anchors.rightMargin: -root.topRightFlare
            visible: false

            Visualisers.NCS {
                id: ncs

                property bool slidIn: false
                Component.onCompleted: Qt.callLater(() => ncs.slidIn = Qt.binding(() => root.entered))

                transform: Translate {
                    x: ShellConfig.px(180) + (ncs.slidIn ? 0 : ncs.width)
                    y: ShellConfig.px(-35)

                    Behavior on x {
                        NumberAnimation {
                            duration: 700
                            easing.type: Easing.OutQuint
                        }
                    }
                }

                active: root.entered && root.players.length > 0
                visible: active

                width: ShellConfig.px(380)
                height: ShellConfig.px(380)

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: root.topRightFlare
            }
        }

        Item {
            id: maskContainer
            anchors.fill: parent
            anchors.rightMargin: -root.topRightFlare
            visible: false
            layer.enabled: true

            Shape {
                id: ncsMaskShape
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                readonly property real bodyWidth: width - root.topRightFlare
                readonly property real maxRadius: Math.min(bodyWidth, height) / 2
                readonly property real topRadius: Math.min(Math.max(root.topRightRadius, 0), maxRadius)
                readonly property real bottomRadius: Math.min(Math.max(root.bottomRightRadius, 0), maxRadius)
                readonly property real flare: Math.min(root.topRightFlare, height / 2)

                ShapePath {
                    fillColor: "black"
                    strokeWidth: 0
                    startX: 0
                    startY: 0

                    PathLine {
                        x: ncsMaskShape.flare > 0 ? ncsMaskShape.bodyWidth + ncsMaskShape.flare : ncsMaskShape.bodyWidth - ncsMaskShape.topRadius
                        y: 0
                    }
                    PathArc {
                        x: ncsMaskShape.bodyWidth
                        y: ncsMaskShape.flare > 0 ? ncsMaskShape.flare : ncsMaskShape.topRadius
                        radiusX: Math.max(ncsMaskShape.flare > 0 ? ncsMaskShape.flare : ncsMaskShape.topRadius, 0.01)
                        radiusY: radiusX
                        direction: ncsMaskShape.flare > 0 ? PathArc.Counterclockwise : PathArc.Clockwise
                    }
                    PathLine {
                        x: ncsMaskShape.bodyWidth
                        y: ncsMaskShape.height - ncsMaskShape.bottomRadius
                    }
                    PathArc {
                        x: ncsMaskShape.bodyWidth - ncsMaskShape.bottomRadius
                        y: ncsMaskShape.height
                        radiusX: Math.max(ncsMaskShape.bottomRadius, 0.01)
                        radiusY: radiusX
                        direction: PathArc.Clockwise
                    }
                    PathLine {
                        x: 0
                        y: ncsMaskShape.height
                    }
                }
            }
        }

        MultiEffect {
            anchors.fill: parent
            anchors.rightMargin: -root.topRightFlare
            source: sourceContainer
            maskEnabled: true
            maskSource: maskContainer
        }

        ColumnLayout {
            id: columnLayout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

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

                        function postTrackChanged() {
                            updatePlayer();
                        }

                        function onLengthChanged() {
                            updatePlayer();
                        }

                        function onPlaybackStateChanged() {
                            if (modelData.playbackState != MprisPlaybackState.Playing)
                                updatePlayer();
                        }
                    }
                }
            }

            Pane {
                id: pane

                horizontalPadding: ShellConfig.px(50)
                verticalPadding: ShellConfig.px(20)

                Layout.fillWidth: true
                Layout.topMargin: ShellConfig.px(20)
                Layout.leftMargin: ShellConfig.px(10)
                Layout.rightMargin: ShellConfig.px(10)
                Layout.bottomMargin: ShellConfig.px(40)

                background: Item {
                    Visualisers.Card {
                        id: pill
                        active: root.entered
                        visible: root.entered
                        anchors.fill: parent
                    }

                    Rectangle {
                        function mix(a, b) {
                            return Qt.rgba((a.r + b.r) / 2, (a.g + b.g) / 2, (a.b + b.b) / 2, (a.a + b.a) / 2);
                        }

                        readonly property real dpr: Screen.devicePixelRatio
                        readonly property real sidePadding: (Math.floor((parent.width * dpr % 10) / 2) + 35 + 5 - 20) / dpr

                        visible: root.entered && !pill.ready
                        anchors.fill: parent
                        anchors.topMargin: 6 / dpr
                        anchors.bottomMargin: 6 / dpr
                        anchors.leftMargin: sidePadding
                        anchors.rightMargin: sidePadding
                        radius: 20 / dpr
                        color: Qt.alpha(Colors.primary_container, 0.15)
                        border.width: 1
                        border.color: mix(mix(Colors.outline, Qt.alpha(Colors.primary_container, 0.15)), Qt.rgba(1, 1, 1, 1))
                    }
                }

                contentItem: ColumnLayout {
                    id: contentColumn
                    Text {
                        text: "No Media Players Detected"
                        color: Colors.on_primary_container
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: ShellConfig.fontPx(20)
                        visible: Mpris.players.values.length === 0
                    }

                    RowLayout {
                        visible: Mpris.players.values.length != 0
                        spacing: ShellConfig.px(20)

                        Item {
                            id: rect
                            width: ShellConfig.px(150)
                            height: ShellConfig.px(150)

                            clip: true

                            visible: lastActivePlayer ? true : false

                            Item {
                                width: rect.width
                                height: rect.height
                                Rectangle {
                                    id: maskShape
                                    anchors.fill: parent
                                    radius: ShellConfig.px(20)

                                    visible: false
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: ShellConfig.px(20)
                                    border.width: .75
                                    color: "transparent"
                                    border.color: Colors.outline
                                    Image {
                                        id: imageArt
                                        anchors.fill: parent
                                        anchors.margins: ShellConfig.px(2)
                                        fillMode: Image.PreserveAspectCrop

                                        sourceSize.width: parent.width
                                        sourceSize.height: parent.height

                                        source: lastActivePlayer ? lastActivePlayer.trackArtUrl : ""

                                        visible: true
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: maskShape
                                        }
                                    }
                                }
                            }
                        }
                        Pane {
                            padding: 0
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            clip: true
                            background: Item {
                                visible: (lastActivePlayer?.length ?? 0) > 0
                                anchors.fill: parent
                                transform: [
                                    Translate {
                                        x: (lastActivePlayer && lastActivePlayer.length > 0) ? (rw.shownPos / lastActivePlayer.length - 1) * progressBarBg.width : 0
                                        y: ShellConfig.px(-30)
                                    }
                                ]
                                Item {
                                    anchors.fill: parent
                                    anchors.bottom: parent.bottom

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: ShellConfig.px(112)
                                        anchors.bottomMargin: ShellConfig.px(-1)
                                        Visualisers.BottomWaves {
                                            active: root.entered
                                            visible: root.entered
                                            anchors.fill: parent
                                        }
                                    }

                                    Item {
                                        width: parent.width
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: ShellConfig.px(112)
                                        anchors.bottomMargin: ShellConfig.px(-1)

                                        Visualisers.TopWaves {
                                            active: root.entered
                                            visible: root.entered
                                            anchors.fill: parent
                                        }
                                    }
                                }
                            }
                            ColumnLayout {
                                id: background
                                anchors.fill: parent
                                anchors.top: parent.top
                                spacing: ShellConfig.px(30)
                                ColumnLayout {
                                    id: titleAndArtistColumn
                                    spacing: ShellConfig.px(30)
                                    Item {
                                        id: titleContainer
                                        Layout.fillWidth: true
                                        Text {
                                            id: titleText
                                            Layout.alignment: Qt.AlignVCenter
                                            font.pixelSize: ShellConfig.fontPx(16)
                                            font.weight: Font.Bold

                                            color: Colors.on_primary_container
                                            text: lastActivePlayer ? lastActivePlayer.trackTitle : ""

                                            wrapMode: Text.NoWrap

                                            onTextChanged: {
                                                marqueeAnimation.stop();
                                                x = 0;

                                                if (paintedWidth > titleContainer.width)
                                                    marqueeAnimation.start();
                                            }
                                            SequentialAnimation on x {
                                                id: marqueeAnimation

                                                running: titleText.paintedWidth > titleContainer.width && titleText.text !== ""

                                                loops: Animation.Infinite

                                                PauseAnimation {
                                                    duration: 1200
                                                }

                                                NumberAnimation {
                                                    from: 0
                                                    to: -(titleText.paintedWidth - titleContainer.width)
                                                    duration: Math.max(2000, (titleText.paintedWidth - titleContainer.width) * 30)
                                                    easing.type: Easing.Linear
                                                }

                                                PauseAnimation {
                                                    duration: 1200
                                                }

                                                NumberAnimation {
                                                    from: -(titleText.paintedWidth - titleContainer.width)
                                                    to: 0
                                                    duration: 800
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }
                                        }
                                    }
                                    Text {
                                        font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                                        Layout.alignment: Qt.AlignVCenter
                                        color: Colors.on_primary_container
                                        text: lastActivePlayer ? lastActivePlayer.trackArtist != "" ? lastActivePlayer.trackArtist : lastActivePlayer.trackAlbum : ""
                                    }
                                }
                                Item {
                                    id: dmabufContainer
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ShellConfig.px(55)

                                    clip: true
                                    ColumnLayout {
                                        id: positionAndTimeColumn

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom

                                        spacing: ShellConfig.px(10)

                                        Rectangle {
                                            id: progressBarBg
                                            Layout.fillWidth: true

                                            Layout.preferredHeight: ShellConfig.px(6)
                                            color: Colors.primary_container
                                            radius: ShellConfig.px(10)

                                            property bool scrubbing: false
                                            property real scrubPosition: 0

                                            function positionAt(x) {
                                                return Math.max(0, Math.min(1, x / width)) * lastActivePlayer.length;
                                            }

                                            MouseArea {
                                                enabled: (lastActivePlayer?.canSeek ?? false) && (lastActivePlayer?.length ?? 0) > 0
                                                anchors.fill: parent
                                                anchors.topMargin: ShellConfig.px(-8)
                                                anchors.bottomMargin: ShellConfig.px(-8)
                                                preventStealing: true
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                                                onPressed: mouse => {
                                                    progressBarBg.scrubPosition = progressBarBg.positionAt(mouse.x);
                                                    progressBarBg.scrubbing = true;
                                                }
                                                onPositionChanged: mouse => {
                                                    if (pressed)
                                                        progressBarBg.scrubPosition = progressBarBg.positionAt(mouse.x);
                                                }
                                                onReleased: {
                                                    if (!progressBarBg.scrubbing)
                                                        return;
                                                    lastActivePlayer.position = progressBarBg.scrubPosition;
                                                    rw.currentPos = progressBarBg.scrubPosition;
                                                    progressBarBg.scrubbing = false;
                                                }
                                                onCanceled: progressBarBg.scrubbing = false
                                            }

                                            Rectangle {
                                                id: progressFill
                                                height: parent.height
                                                radius: parent.radius

                                                color: Colors.primary

                                                width: (lastActivePlayer && lastActivePlayer.length > 0) ? (rw.shownPos / lastActivePlayer.length) * parent.width : 0
                                            }
                                        }
                                        RowLayout {
                                            id: rw
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignTop

                                            property real currentPos: lastActivePlayer ? lastActivePlayer.position : 0
                                            readonly property real shownPos: progressBarBg.scrubbing ? progressBarBg.scrubPosition : currentPos

                                            Text {
                                                text: formatTime(progressBarBg.scrubbing ? progressBarBg.scrubPosition : (lastActivePlayer?.position ?? 0))
                                                font.pixelSize: ShellConfig.fontPx(12)
                                                color: Colors.on_primary_container
                                            }

                                            FrameAnimation {
                                                running: lastActivePlayer && (lastActivePlayer.playbackState == MprisPlaybackState.Playing)
                                                onTriggered: {
                                                    if (!lastActivePlayer)
                                                        return;

                                                    lastActivePlayer.positionChanged();
                                                    rw.currentPos = lastActivePlayer.position;
                                                }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: formatTime(lastActivePlayer?.length ?? 0)
                                                font.pixelSize: ShellConfig.fontPx(12)
                                                color: Colors.on_primary_container
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                visible: Mpris.players.values.length != 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                Item {
                    Layout.fillWidth: true
                }

                Pane {
                    padding: 0
                    Layout.bottomMargin: ShellConfig.px(20)
                    Layout.topMargin: ShellConfig.px(-10)
                    Layout.leftMargin: ShellConfig.px(6)
                    Layout.rightMargin: ShellConfig.px(6)
                    Material.theme: Colors.isDark ? Material.Dark : Material.Light
                    Material.accent: Colors.primary
                    Material.primary: Colors.primary

                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                    background: Rectangle {
                        color: Qt.rgba(Colors.on_primary.r, Colors.on_primary.g, Colors.on_primary.b, .75)
                        border.color: Colors.outline
                        border.width: .5
                        radius: ShellConfig.px(30)
                    }
                    contentItem: RowLayout {
                        id: buttons
                        spacing: ShellConfig.px(15)

                        Layout.fillHeight: false
                        Layout.fillWidth: true

                        Item {}

                        RoundButton {
                            id: shuffleButton
                            width: ShellConfig.px(60)
                            height: ShellConfig.px(60)
                            enabled: lastActivePlayer && lastActivePlayer.shuffleSupported
                            onClicked: lastActivePlayer.shuffle = !lastActivePlayer.shuffle
                            Material.foreground: Colors.on_primary_container

                            background: Item {
                                Rectangle {
                                    width: ShellConfig.px(4)
                                    visible: shuffleButton.enabled && lastActivePlayer.shuffle
                                    height: ShellConfig.px(4)
                                    radius: ShellConfig.px(2)
                                    anchors.centerIn: parent
                                    color: Colors.on_surface

                                    transform: Translate {
                                        y: ShellConfig.px(16)
                                        x: ShellConfig.px(-2)
                                    }
                                }
                            }
                            contentItem: Text {
                                color: shuffleButton.enabled ? Colors.on_primary_container : Colors.disabled
                                font.pixelSize: ShellConfig.fontPx(23)
                                text: ""
                                antialiasing: true
                                transform: [
                                    Translate {
                                        y: ShellConfig.px(2)
                                    }
                                ]
                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                        FifteenSecondsButton {
                            isForward: false
                        }

                        RoundButton {
                            id: previousButton
                            font.pointSize: 32 * ShellConfig.fontScale
                            verticalPadding: ShellConfig.px(4)
                            horizontalPadding: ShellConfig.px(16)
                            rightPadding: ShellConfig.px(8)
                            text: "󰒮"
                            Material.foreground: Colors.on_primary_container
                            background: Item {}

                            enabled: lastActivePlayer && lastActivePlayer?.canGoPrevious
                            onClicked: lastActivePlayer?.previous()
                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        RoundButton {
                            id: playPauseButton
                            font.pointSize: 32 * ShellConfig.fontScale
                            verticalPadding: ShellConfig.px(4)
                            horizontalPadding: ShellConfig.px(16)
                            background: Item {}
                            Material.foreground: Colors.on_primary_container

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                            text: (lastActivePlayer && lastActivePlayer.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                            enabled: lastActivePlayer
                            onClicked: {
                                if (lastActivePlayer) {
                                    if (lastActivePlayer.playbackState === MprisPlaybackState.Playing)
                                        lastActivePlayer.pause();
                                    else
                                        lastActivePlayer.play();
                                }
                            }
                        }

                        RoundButton {
                            id: nextButton
                            font.pointSize: 32 * ShellConfig.fontScale
                            verticalPadding: ShellConfig.px(4)
                            horizontalPadding: ShellConfig.px(16)
                            leftPadding: ShellConfig.px(8)

                            text: "󰒭"
                            background: Item {}
                            Material.foreground: Colors.on_primary_container

                            enabled: lastActivePlayer && lastActivePlayer?.canGoNext
                            onClicked: lastActivePlayer?.next()
                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                        FifteenSecondsButton {}

                        Pane {
                            padding: 0
                            background: Item {
                                Rectangle {
                                    visible: lastActivePlayer && lastActivePlayer.loopState == MprisLoopState.Playlist
                                    width: ShellConfig.px(4)
                                    height: ShellConfig.px(4)
                                    radius: ShellConfig.px(2)
                                    anchors.centerIn: parent
                                    color: Colors.on_surface
                                }
                                Text {
                                    font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                                    visible: lastActivePlayer && lastActivePlayer.loopState == MprisLoopState.Track
                                    text: "1"
                                    anchors.centerIn: parent
                                    color: Colors.on_surface
                                }
                            }
                            RoundButton {
                                id: loopButton
                                background: Item {}
                                enabled: lastActivePlayer && lastActivePlayer.loopSupported
                                Material.foreground: Colors.on_primary_container

                                onClicked: {
                                    if (!lastActivePlayer || !lastActivePlayer.loopSupported)
                                        return;

                                    if (lastActivePlayer.loopState === MprisLoopState.None)
                                        lastActivePlayer.loopState = MprisLoopState.Playlist;
                                    else if (lastActivePlayer.loopState === MprisLoopState.Playlist)
                                        lastActivePlayer.loopState = MprisLoopState.Track;
                                    else if (lastActivePlayer.loopState === MprisLoopState.Track)
                                        lastActivePlayer.loopState = MprisLoopState.None;
                                }
                                contentItem: Item {
                                    id: loopButtonRectangle
                                    property int length: ShellConfig.px(25)
                                    property int breadth: ShellConfig.px(24)
                                    property int curveRadius: ShellConfig.px(5)
                                    property int arrowHeight: ShellConfig.px(5)
                                    property int arrowWidth: ShellConfig.px(6)
                                    property int bottomLengthExtent: ShellConfig.px(13)
                                    anchors.centerIn: parent
                                    anchors.fill: parent
                                    implicitWidth: ShellConfig.px(40)
                                    implicitHeight: ShellConfig.px(20)
                                    Shape {
                                        preferredRendererType: Shape.CurveRenderer
                                        anchors.fill: parent
                                        anchors.centerIn: parent
                                        layer.enabled: true
                                        antialiasing: true

                                        ShapePath {
                                            strokeColor: loopButton.enabled ? Colors.on_primary_container : Colors.disabled
                                            strokeWidth: 2
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap

                                            PathMove {
                                                relativeX: loopButtonRectangle.width / 2 - loopButtonRectangle.length / 2 + loopButtonRectangle.curveRadius / 2
                                                relativeY: loopButtonRectangle.height / 2 - loopButtonRectangle.breadth / 2
                                            }
                                            PathLine {
                                                relativeX: loopButtonRectangle.length - loopButtonRectangle.curveRadius
                                                relativeY: 0
                                            }

                                            PathArc {
                                                radiusX: loopButtonRectangle.curveRadius
                                                radiusY: loopButtonRectangle.curveRadius
                                                relativeX: loopButtonRectangle.curveRadius
                                                relativeY: loopButtonRectangle.curveRadius
                                            }
                                            PathLine {
                                                relativeX: 0
                                                relativeY: loopButtonRectangle.breadth - 2 * loopButtonRectangle.curveRadius
                                            }
                                            PathArc {
                                                radiusX: loopButtonRectangle.curveRadius
                                                radiusY: loopButtonRectangle.curveRadius
                                                relativeX: -loopButtonRectangle.curveRadius
                                                relativeY: loopButtonRectangle.curveRadius
                                            }
                                            PathLine {
                                                relativeX: -Math.min(loopButtonRectangle.bottomLengthExtent, loopButtonRectangle.length - 2 * loopButtonRectangle.curveRadius)
                                                relativeY: 0
                                            }
                                            PathLine {
                                                relativeX: loopButtonRectangle.arrowWidth
                                                relativeY: -loopButtonRectangle.arrowHeight
                                            }

                                            PathMove {
                                                relativeX: 0
                                                relativeY: 2 * loopButtonRectangle.arrowHeight
                                            }

                                            PathLine {
                                                relativeX: -loopButtonRectangle.arrowWidth
                                                relativeY: -loopButtonRectangle.arrowHeight
                                            }

                                            PathMove {
                                                relativeX: -(loopButtonRectangle.length - loopButtonRectangle.curveRadius - loopButtonRectangle.bottomLengthExtent)
                                                relativeY: 0
                                            }

                                            PathArc {
                                                radiusX: loopButtonRectangle.curveRadius
                                                radiusY: loopButtonRectangle.curveRadius
                                                relativeX: -loopButtonRectangle.curveRadius
                                                relativeY: -loopButtonRectangle.curveRadius
                                            }
                                            PathLine {
                                                relativeX: 0
                                                relativeY: -(loopButtonRectangle.breadth - 2 * loopButtonRectangle.curveRadius)
                                            }
                                            PathArc {
                                                radiusX: loopButtonRectangle.curveRadius
                                                radiusY: loopButtonRectangle.curveRadius
                                                relativeX: loopButtonRectangle.curveRadius
                                                relativeY: -loopButtonRectangle.curveRadius
                                            }
                                        }
                                    }

                                    HoverHandler {
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }

                        Item {}
                    }
                }

                Item {
                    id: itemFiller
                    Layout.fillWidth: true
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        Notch {
            id: bottomNotch
            anchors.horizontalCenter: parent.horizontalCenter
            configObject: root.bottomNotchConfig

            headerContent: RowLayout {
                anchors.fill: parent
                Rectangle {
                    id: rect1

                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignCenter
                    Visualisers.Logo {
                        anchors.fill: parent
                        active: root.entered && !bottomNotch.expanded
                        visible: root.entered && !bottomNotch.expanded
                    }
                }
            }

            panelContent: ColumnLayout {
                Rectangle {
                    id: rect2
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    Visualisers.Logo {
                        anchors.fill: parent
                        active: root.entered && bottomNotch.expanded
                        visible: root.entered && bottomNotch.expanded
                    }
                }
            }
        }
    }

    component PlayerSelector: Notch {

        direction: Directions.Left

        headerContent: ColumnLayout {
            Rectangle {
                Layout.alignment: Qt.AlignCenter
                width: ShellConfig.px(10)
                color: Colors.primary
                height: ShellConfig.px(10)
                radius: ShellConfig.px(10)
            }
        }

        panelContent: ColumnLayout {
            spacing: ShellConfig.px(12)

            Repeater {
                model: Mpris.players
                delegate: Rectangle {
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: childrenRect.width
                    implicitHeight: childrenRect.height
                    color: modelData === lastActivePlayer ? Colors.primary_container : "transparent"
                    border.width: 1
                    border.color: Colors.primary
                    radius: ShellConfig.px(40)
                    ScaledRoundButton {
                        id: button
                        spacing: 0
                        rightInset: 0
                        leftInset: 0
                        topInset: 0
                        bottomInset: 0
                        flat: true
                        text: modelData.identity
                        checked: modelData === lastActivePlayer
                        onClicked: lastActivePlayer = modelData
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    component FifteenSecondsButton: Pane {
        id: pane
        property bool isForward: true
        readonly property int buttonSign: isForward ? 1 : -1
        padding: 0
        background: Item {
            z: 1
            Text {
                z: 2
                transform: Translate {
                    y: ShellConfig.px(9)
                    x: pane.buttonSign * ShellConfig.px(8)
                }
                text: "15"
                font.pixelSize: ShellConfig.fontPx(16)
                color: Colors.on_primary_container
                anchors.centerIn: parent
            }
        }
        RoundButton {
            id: fifteenSecondsButton

            enabled: lastActivePlayer
            anchors.centerIn: parent
            onClicked: {
                if (!lastActivePlayer)
                    return;
                let target = Math.max(0, lastActivePlayer.position + buttonSign * 15);
                if (lastActivePlayer.lengthSupported && lastActivePlayer.length > 0)
                    target = Math.min(target, lastActivePlayer.length);
                lastActivePlayer.position = target;
            }
            width: ShellConfig.px(60)
            background: Item {}
            height: ShellConfig.px(60)
            contentItem: Item {
                anchors.centerIn: parent
                anchors.fill: parent
                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    anchors.fill: parent
                    layer.enabled: true
                    antialiasing: true

                    ShapePath {
                        strokeColor: fifteenSecondsButton.enabled ? Colors.on_primary_container : Colors.disabled
                        strokeWidth: ShellConfig.px(2)
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: fifteenSecondsButton.width / 2
                            centerY: fifteenSecondsButton.height / 2
                            radiusX: fifteenSecondsButton.width / 2 - ShellConfig.px(17)
                            radiusY: fifteenSecondsButton.width / 2 - ShellConfig.px(17)

                            startAngle: 90 + pane.buttonSign * 25
                            sweepAngle: pane.buttonSign * 230
                        }

                        PathMove {
                            relativeX: pane.buttonSign * 1.5 * ShellConfig.sizeScale
                            relativeY: 0
                        }
                        PathLine {
                            relativeX: 0
                            relativeY: -ShellConfig.px(5)
                        }
                        PathMove {
                            relativeX: -1.5 * pane.buttonSign * ShellConfig.sizeScale
                            relativeY: ShellConfig.px(5)
                        }
                        PathLine {
                            relativeX: -ShellConfig.px(4) * pane.buttonSign
                            relativeY: 0
                        }
                    }
                }
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
