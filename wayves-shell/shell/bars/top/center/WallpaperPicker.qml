import QtQuick
import QtQuick.Controls.Material
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

import QtMultimedia

import Qt.labs.folderlistmodel

import Quickshell
import Quickshell.Io

import qs.components.media
import qs.config.theme
import qs.services
import qs.Visualisers
import qs.config

Pane {
    id: root
    implicitWidth: Quickshell.screens[0].width - ShellConfig.px(60)
    implicitHeight: Quickshell.screens[0].height - ShellConfig.px(20)

    property bool entered: false
    property bool wasEntered: false

    function enter() {
        wasEntered = true;
        grid.focusApplied();
        grid.forceActiveFocus();
    }

    function leave() {
        if (!wasEntered)
            return;
        wasEntered = false;
        VideoPreviews.changeVideo("");
        VideoPreviews.shouldPlay = false;
        VideoPreviews.stop();
        cardPalette.restore();
    }

    onEnteredChanged: entered ? enter() : leave()
    Component.onCompleted: if (entered)
        enter()
    Component.onDestruction: leave()

    QtObject {
        id: cardPalette

        property var cache: ({})
        property string wanted: ""
        property color shown: Colors.primary
        property string runningPath: ""
        readonly property int prefetchReach: 2

        function request(path) {
            wanted = path;
            if (path === "")
                return;
            if (cache[path] !== undefined) {
                if (cache[path])
                    push(cache[path]);
                runNext();
                return;
            }
            if (!matugen.running)
                run(path);
        }

        function runNext() {
            if (matugen.running || !root.entered)
                return;
            if (wanted !== "" && cache[wanted] === undefined) {
                run(wanted);
                return;
            }
            for (let d = 1; d <= prefetchReach; d++) {
                for (const i of [grid.currentIndex + d, grid.currentIndex - d]) {
                    const path = pathAt(i);
                    if (path !== "" && cache[path] === undefined) {
                        run(path);
                        return;
                    }
                }
            }
        }

        function pathAt(i) {
            if (i < 0 || i >= grid.count)
                return "";
            const path = grid.model.get(i, "filePath");
            return MediaFormats.isVideo(grid.model.get(i, "fileSuffix")) ? (Thumbnails.ready[path] ?? "") : path;
        }

        function run(path) {
            runningPath = path;
            matugen.command = ["matugen", "image", path, "-m", Colors.isDark ? "dark" : "light", "--source-color-index", "0", "--dry-run", "--json", "hex"];
            matugen.running = true;
        }

        function push(primary) {
            if (!root.entered)
                return;
            Colors.updateWayVesColors("primary=" + primary, "ncs_card");
            const [r, g, b] = primary.match(/\d+/g);
            shown = Qt.rgba(r / 255, g / 255, b / 255, 1);
        }

        function restore() {
            wanted = "";
            shown = Colors.primary;
            Colors.updateWayVesColors("primary=" + Colors.themeFile.adapter.primary_rgba, "ncs_card");
        }

        function primaryOf(json) {
            const c = Qt.color(JSON.parse(json).colors.primary.default.color);
            return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, 1)`;
        }
    }

    Process {
        id: matugen

        stdout: StdioCollector {
            onStreamFinished: {
                const path = cardPalette.runningPath;
                try {
                    cardPalette.cache[path] = cardPalette.primaryOf(text);
                } catch (e) {
                    cardPalette.cache[path] = null;
                }
                if (path === cardPalette.wanted && cardPalette.cache[path])
                    cardPalette.push(cardPalette.cache[path]);
            }
        }

        onExited: Qt.callLater(cardPalette.runNext)
    }

    Connections {
        target: Colors
        function onIsDarkChanged() {
            cardPalette.cache = {};
            if (cardPalette.wanted !== "")
                cardPalette.request(cardPalette.wanted);
        }
    }

    Material.theme: Colors.isDark ? Material.Dark : Material.Light
    Material.accent: Colors.primary
    Material.primary: Colors.primary
    clip: true

    transform: Translate {
        y: ShellConfig.px(-120)
    }

    background: Rectangle {
        color: "transparent"
        anchors.fill: parent

        Visualisers.WallpaperBackground {
            width: root.implicitWidth
            height: root.implicitHeight
            active: root.entered
            visible: root.entered
        }
    }
    ColumnLayout {
        id: pickerWindow
        anchors.fill: parent
        spacing: ShellConfig.px(12)

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: themeSwitch.height
            color: "transparent"
            transform: Translate {
                y: ShellConfig.px(150)
            }
            ThemeSwitch {
                id: themeSwitch
                active: root.entered
                anchors.right: parent.right
                anchors.rightMargin: ShellConfig.px(20)
            }
        }

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true

            transform: [
                Translate {
                    y: ShellConfig.px(40)
                },
                Rotation {
                    angle: -9
                    origin.x: stage.width / 2.
                    origin.y: scene.y + wallpaperRect.y + wallpaperRect.height / 2.
                    axis {
                        x: 0
                        y: 0
                        z: 1
                    }
                },
                Rotation {
                    angle: 25
                    origin.x: stage.width / 2.
                    origin.y: scene.y + wallpaperRect.y + wallpaperRect.height / 2.
                    axis {
                        x: 1
                        y: 0
                        z: 0
                    }
                }
            ]

            Item {
                id: reflectionMask
                width: 64
                height: 64
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "white"
                        }
                        GradientStop {
                            position: 0.45
                            color: "transparent"
                        }
                    }
                }
            }

            Column {
                id: scene
                anchors.centerIn: parent
                width: parent.width
                spacing: ShellConfig.px(40)
                Rectangle {
                    id: videoContainer
                    width: ShellConfig.px(1000)
                    height: ShellConfig.px(400)
                    radius: ShellConfig.px(24)

                    transform: Translate {
                        x: ShellConfig.px(80)
                        y: ShellConfig.px(-450)
                    }

                    color: 'transparent'
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        id: imageContainer
                        anchors.fill: parent
                        anchors.margins: ShellConfig.px(2)
                        source: ""
                        visible: false
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    VideoOutput {
                        id: vOutput
                        visible: false
                        anchors.fill: parent
                        anchors.centerIn: parent
                        fillMode: VideoOutput.PreserveAspectCrop

                        property bool hasFreshFrame: false

                        Connections {
                            target: vOutput.videoSink
                            function onVideoFrameChanged() {
                                if (VideoPreviews.playing)
                                    vOutput.hasFreshFrame = true;
                            }
                        }
                    }
                    MultiEffect {
                        source: imageContainer
                        anchors.fill: imageContainer
                        maskEnabled: imageContainer.source != ""
                        maskSource: mask
                    }
                    MultiEffect {
                        source: vOutput
                        anchors.fill: vOutput
                        visible: grid.focusIsVideo && VideoPreviews.playing && vOutput.hasFreshFrame
                        maskEnabled: true
                        maskSource: mask
                    }

                    Item {
                        id: mask
                        width: vOutput.width
                        height: vOutput.height
                        layer.enabled: true
                        visible: false

                        Rectangle {
                            anchors.fill: parent
                            radius: videoContainer.radius
                            color: "white"
                        }
                    }

                    Column {
                        visible: grid.focusPath !== ""
                        anchors.top: parent.bottom
                        anchors.topMargin: ShellConfig.px(20)
                        anchors.left: parent.left
                        anchors.leftMargin: ShellConfig.px(8)
                        spacing: ShellConfig.px(8)

                        Text {
                            text: grid.focusPath.split("/").pop().replace(/\.[^.]+$/, "")
                            color: Colors.on_surface
                            font.pixelSize: ShellConfig.fontPx(32)
                            font.weight: Font.DemiBold
                            renderType: Text.QtRendering
                            antialiasing: true
                        }

                        Row {
                            spacing: ShellConfig.px(12)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: grid.focusIsVideo ? "VIDEO" : "IMAGE  ·  " + imageContainer.sourceSize.width + " × " + imageContainer.sourceSize.height
                                color: Colors.on_surface
                                opacity: 0.7
                                font.pixelSize: ShellConfig.fontPx(16)
                                font.letterSpacing: 1.5
                                renderType: Text.QtRendering
                                antialiasing: true
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: "file://" + grid.focusPath === Theme.wallpaperSource
                                width: appliedLabel.implicitWidth + ShellConfig.px(20)
                                height: appliedLabel.implicitHeight + ShellConfig.px(8)
                                radius: height / 2
                                color: Colors.primary

                                Text {
                                    id: appliedLabel
                                    anchors.centerIn: parent
                                    text: "APPLIED"
                                    color: Colors.on_primary
                                    font.pixelSize: ShellConfig.fontPx(13)
                                    font.letterSpacing: 1.5
                                    font.weight: Font.DemiBold
                                    renderType: Text.QtRendering
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: videoContainer.radius
                        visible: imageContainer.source != ""
                        border.width: 2
                        border.pixelAligned: false
                        antialiasing: true
                        border.color: "white"
                        color: "transparent"
                    }
                }
                Rectangle {
                    id: wallpaperRect
                    width: parent.width
                    height: ShellConfig.px(180)
                    color: "transparent"

                    ListView {
                        id: grid
                        readonly property real itemWidth: ShellConfig.px(370)
                        property string focusPath: ""
                        property bool focusIsVideo: false
                        property real reflectionGap: ShellConfig.px(24)
                        property string typedPrefix: ""

                        function focusApplied() {
                            const videos = [];
                            for (let i = 0; i < count; i++) {
                                const path = model.get(i, "filePath");
                                if (MediaFormats.isVideo(model.get(i, "fileSuffix")))
                                    videos.push(path);
                                if ("file://" + path === Theme.wallpaperSource) {
                                    currentIndex = i;
                                    positionViewAtIndex(i, ListView.Center);
                                }
                            }
                            currentItem?.showInHero();
                            VideoPreviews.preparePreviews(videos);
                        }

                        function jumpToTyped(character) {
                            typedPrefix += character;
                            typeAheadReset.restart();

                            for (let i = 0; i < count; i++) {
                                if (model.get(i, "fileName").toLowerCase().startsWith(typedPrefix)) {
                                    currentIndex = i;
                                    return;
                                }
                            }
                        }

                        orientation: ListView.Horizontal
                        anchors.fill: parent
                        anchors.centerIn: parent
                        anchors.leftMargin: ShellConfig.px(20)
                        anchors.rightMargin: ShellConfig.px(20)
                        spacing: ShellConfig.px(70)

                        highlightRangeMode: ListView.StrictlyEnforceRange
                        preferredHighlightBegin: width / 2 - itemWidth / 2
                        preferredHighlightEnd: width / 2 + itemWidth / 2
                        highlight: Item {}
                        highlightMoveDuration: 350
                        highlightMoveVelocity: -1

                        Item {
                            id: cardBackerHolder
                            parent: grid.contentItem
                            readonly property Item current: grid.currentItem
                            readonly property real cardWidth: (current?.width ?? grid.itemWidth) - ShellConfig.px(10)
                            readonly property real cardHeight: (current?.height ?? ShellConfig.px(160)) - ShellConfig.px(10)

                            visible: root.entered && current !== null
                            width: cardWidth + ShellConfig.px(400)
                            height: cardHeight + ShellConfig.px(200)
                            z: 1.5
                            x: current ? current.x + current.width / 2 - width / 2 : 0
                            y: current ? current.y + current.height / 2 - height / 2 : 0

                            Visualisers.WallpaperPickerBackground {
                                id: cardBacker
                                anchors.fill: parent
                                active: root.entered
                                visible: root.entered
                            }

                            RectangularGlow {
                                visible: root.entered && !cardBacker.ready
                                anchors.centerIn: parent
                                width: cardBackerHolder.cardWidth
                                height: cardBackerHolder.cardHeight
                                glowRadius: 70
                                spread: 0.1
                                cornerRadius: 5 + glowRadius
                                color: Qt.alpha(cardPalette.shown, Colors.isDark ? 0.45 : 0.6)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }
                            }
                        }

                        focus: true
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Home) {
                                currentIndex = 0;
                            } else if (event.key === Qt.Key_End) {
                                currentIndex = count - 1;
                            } else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
                                const page = Math.max(1, Math.floor(width / (itemWidth + spacing)));
                                const step = event.key === Qt.Key_PageUp ? -page : page;
                                currentIndex = Math.max(0, Math.min(count - 1, currentIndex + step));
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                currentItem?.apply();
                            } else if (event.text.length === 1 && event.text > " ") {
                                jumpToTyped(event.text.toLowerCase());
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }

                        Timer {
                            id: typeAheadReset
                            interval: 900
                            onTriggered: grid.typedPrefix = ""
                        }

                        WheelHandler {
                            property real accumulated: 0

                            onWheel: event => {
                                accumulated += event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y;
                                while (Math.abs(accumulated) >= 120) {
                                    const step = accumulated > 0 ? -1 : 1;
                                    accumulated += step * 120;
                                    grid.currentIndex = Math.max(0, Math.min(grid.count - 1, grid.currentIndex + step));
                                }
                            }
                        }

                        Connections {
                            target: grid.model

                            function onStatusChanged() {
                                if (grid.model.status === FolderListModel.Ready && root.entered)
                                    grid.focusApplied();
                            }
                        }

                        model: FolderListModel {
                            folder: "file://" + ShellConfig.wallpaperDirectory
                            nameFilters: [...MediaFormats.imageFilters, ...MediaFormats.videoFilters]
                            caseSensitive: false
                        }
                        delegate: Item {
                            id: item
                            width: grid.itemWidth
                            height: ShellConfig.px(160)
                            Layout.alignment: Qt.AlignHCenter

                            readonly property int focusDistance: Math.abs(index - grid.currentIndex)
                            readonly property bool isCurrent: ListView.isCurrentItem
                            z: isCurrent ? 2 : 1

                            onIsCurrentChanged: if (isCurrent)
                                showInHero()
                            Component.onCompleted: if (isCurrent)
                                showInHero()

                            function showInHero() {
                                grid.focusPath = filePath;
                                grid.focusIsVideo = previewHolder.isVideo;

                                VideoPreviews.shouldPlay = false;
                                VideoPreviews.stop();
                                vOutput.hasFreshFrame = false;

                                if (root.entered)
                                    cardPalette.request(cardPalette.pathAt(index));

                                if (!previewHolder.isVideo) {
                                    imageContainer.source = fileUrl;
                                    return;
                                }

                                imageContainer.source = previewHolder.videoThumbnailUrl === "" ? "" : "file://" + previewHolder.videoThumbnailUrl;
                                videoStart.restart();
                            }

                            Timer {
                                id: videoStart
                                interval: 450
                                onTriggered: {
                                    if (!item.isCurrent || !root.entered || !ShellConfig.pickerVideoPreviews)
                                        return;
                                    VideoPreviews.shouldPlay = true;
                                    VideoPreviews.videoOutput = vOutput;
                                    VideoPreviews.changeVideo(fileUrl);
                                }
                            }

                            function apply() {
                                Theme.updateWallpaper(filePath);
                            }
                            scale: focusDistance === 0 ? 1 : focusDistance === 1 ? 0.85 : 0.7

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Image {
                                id: reflectionSource
                                width: previewHolder.width
                                height: previewHolder.height
                                source: thumbnail.source
                                sourceSize.width: 64
                                sourceSize.height: 28
                                smooth: true
                                mirrorVertically: true
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false
                            }

                            MultiEffect {
                                source: reflectionSource
                                x: previewHolder.x
                                y: previewHolder.y + previewHolder.height + grid.reflectionGap
                                width: previewHolder.width
                                height: previewHolder.height
                                opacity: 0.35
                                saturation: -0.2
                                brightness: -0.15
                                maskEnabled: true
                                maskSource: reflectionMask
                                maskSpreadAtMin: 1
                            }

                            Rectangle {
                                id: previewHolder
                                anchors.fill: parent
                                anchors.margins: ShellConfig.px(5)
                                color: Colors.surface_container
                                radius: ShellConfig.px(5)
                                border.color: mouseArea.containsMouse ? Colors.primary : "transparent"
                                border.width: 2

                                readonly property bool isVideo: MediaFormats.isVideo(fileSuffix)
                                readonly property bool isApplied: "file://" + filePath === Theme.wallpaperSource
                                readonly property string videoThumbnailUrl: isVideo ? (Thumbnails.ready[filePath] ?? "") : ""
                                onVideoThumbnailUrlChanged: {
                                    if (!item.isCurrent || videoThumbnailUrl === "")
                                        return;
                                    imageContainer.source = "file://" + videoThumbnailUrl;
                                    if (root.entered)
                                        cardPalette.request(videoThumbnailUrl);
                                }
                                property var currentPosition: 0

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: previewHolder.border.width
                                    radius: previewHolder.radius
                                    color: previewHolder.color
                                }
                                Image {
                                    id: thumbnail
                                    anchors.fill: parent
                                    anchors.margins: ShellConfig.px(2)
                                    source: previewHolder.isVideo ? (previewHolder.videoThumbnailUrl === "" ? "" : "file://" + previewHolder.videoThumbnailUrl) : fileUrl
                                    sourceSize.width: grid.itemWidth * 2
                                    sourceSize.height: item.height * 2

                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                Rectangle {
                                    visible: previewHolder.isApplied
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: ShellConfig.px(10)
                                    width: cardAppliedLabel.implicitWidth + ShellConfig.px(16)
                                    height: cardAppliedLabel.implicitHeight + ShellConfig.px(6)
                                    radius: height / 2
                                    color: Colors.primary

                                    Text {
                                        id: cardAppliedLabel
                                        anchors.centerIn: parent
                                        text: "APPLIED"
                                        color: Colors.on_primary
                                        font.pixelSize: ShellConfig.fontPx(11)
                                        font.letterSpacing: 1.2
                                        font.weight: Font.DemiBold
                                        renderType: Text.QtRendering
                                    }
                                }

                                Rectangle {
                                    visible: previewHolder.isVideo && !item.isCurrent
                                    radius: ShellConfig.px(20)
                                    width: ShellConfig.px(40)
                                    height: ShellConfig.px(40)
                                    color: '#7f000000'
                                    anchors.centerIn: parent
                                    Text {
                                        text: "▶"
                                        color: "white"
                                        font.pointSize: 20 * ShellConfig.fontScale
                                        anchors.centerIn: parent

                                        anchors.horizontalCenterOffset: 3
                                        anchors.verticalCenterOffset: -2
                                    }
                                }
                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: {
                                        if (item.isCurrent)
                                            item.apply();
                                        else
                                            grid.currentIndex = index;
                                    }
                                }
                            }
                        }
                    }
                }
                Item {
                    id: filmstrip
                    readonly property real xOffset: ShellConfig.px(80)
                    readonly property real edgeMargin: ShellConfig.px(40)
                    readonly property real maxWidth: Math.max(0, parent.width - 2 * (xOffset + edgeMargin))
                    readonly property real stride: Math.min(ShellConfig.px(36), maxWidth / Math.max(1, grid.count))
                    readonly property real cellSpacing: Math.min(ShellConfig.px(4), stride * 0.12)
                    readonly property real cellWidth: stride - cellSpacing
                    readonly property real cellHeight: ShellConfig.px(18)
                    readonly property real rowStride: grid.itemWidth + grid.spacing
                    readonly property real yOffset: ShellConfig.px(120)
                    readonly property real bottomMargin: ShellConfig.px(16)
                    property real lift: 0

                    function jumpTo(x) {
                        grid.currentIndex = Math.max(0, Math.min(grid.count - 1, Math.floor(x / stride)));
                    }

                    function updateLift() {
                        const baseY = y + yOffset + height;
                        let lowest = -Infinity;
                        let slope = 0;
                        for (const px of [x + xOffset, x + xOffset + width]) {
                            const p = scene.mapToItem(root, px, baseY);
                            const q = scene.mapToItem(root, px, baseY - 1);
                            if (p.y > lowest) {
                                lowest = p.y;
                                slope = p.y - q.y;
                            }
                        }
                        const overshoot = lowest - (root.height - bottomMargin);
                        lift = overshoot > 0 && slope > 0 ? overshoot / slope : 0;
                    }

                    onWidthChanged: Qt.callLater(updateLift)
                    onXChanged: Qt.callLater(updateLift)
                    onYChanged: Qt.callLater(updateLift)
                    Component.onCompleted: Qt.callLater(updateLift)

                    Connections {
                        target: scene
                        function onYChanged() {
                            Qt.callLater(filmstrip.updateLift);
                        }
                    }

                    Connections {
                        target: stage
                        function onWidthChanged() {
                            Qt.callLater(filmstrip.updateLift);
                        }
                        function onHeightChanged() {
                            Qt.callLater(filmstrip.updateLift);
                        }
                    }

                    width: Math.max(grid.count * stride - cellSpacing, 0)
                    height: cellHeight + ShellConfig.px(12)
                    anchors.horizontalCenter: parent.horizontalCenter
                    transform: Translate {
                        y: filmstrip.yOffset - filmstrip.lift
                        x: filmstrip.xOffset
                    }

                    Repeater {
                        model: grid.model

                        delegate: Rectangle {
                            readonly property bool isCurrent: index === grid.currentIndex

                            x: index * filmstrip.stride
                            width: filmstrip.cellWidth
                            height: filmstrip.cellHeight
                            radius: ShellConfig.px(3)
                            color: Qt.alpha(Colors.on_surface, 0.2)
                            border.width: isCurrent ? 2 : 0
                            border.color: Colors.on_surface

                            Image {
                                anchors.fill: parent
                                anchors.margins: parent.border.width
                                source: !MediaFormats.isVideo(fileSuffix) ? fileUrl : Thumbnails.ready[filePath] === undefined ? "" : "file://" + Thumbnails.ready[filePath]
                                sourceSize.width: filmstrip.cellWidth * 2
                                sourceSize.height: filmstrip.cellHeight * 2
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                opacity: parent.isCurrent ? 1 : 0.55

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Rectangle {
                                visible: "file://" + filePath === Theme.wallpaperSource
                                anchors.top: parent.bottom
                                anchors.topMargin: ShellConfig.px(4)
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: ShellConfig.px(6)
                                height: ShellConfig.px(6)
                                radius: ShellConfig.px(3)
                                color: Colors.primary
                            }
                        }
                    }

                    Rectangle {
                        readonly property real windowStart: Math.max(0, grid.contentX / filmstrip.rowStride * filmstrip.stride)
                        readonly property real windowEnd: Math.min(filmstrip.width, (grid.contentX + grid.width) / filmstrip.rowStride * filmstrip.stride)

                        x: windowStart - ShellConfig.px(4)
                        y: ShellConfig.px(-4)
                        width: Math.max(0, windowEnd - windowStart) + ShellConfig.px(8)
                        height: filmstrip.cellHeight + ShellConfig.px(8)
                        radius: ShellConfig.px(6)
                        color: "transparent"
                        border.width: 1
                        border.color: Colors.on_surface
                        opacity: 0.45
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: ShellConfig.px(-8)
                        cursorShape: Qt.PointingHandCursor

                        onPressed: mouse => filmstrip.jumpTo(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                filmstrip.jumpTo(mouse.x);
                        }
                    }
                }
            }
        }
    }
}
