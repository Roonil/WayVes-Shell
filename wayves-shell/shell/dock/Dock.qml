import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import Quickshell.Io
import Quickshell.Hyprland

import qs.config
import qs.components.controls
import qs.components.notch
import qs.config.theme
import qs.enums
import qs.Visualisers

PanelWindow {
    id: root
    anchors.bottom: true

    property real opacity: 1
    property bool hovered: false
    property var configObject: undefined
    readonly property bool workspaceIsEmpty: (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) === 0
    property real hoverHeight: ShellConfig.px(configObject?.hoverHeight ?? 300)
    property real hoverWidth: ShellConfig.px(configObject?.hoverWidth ?? 1600)
    property real activationWidth: ShellConfig.pxOpt(configObject?.activationWidth) ?? hoverWidth
    property real activationHeight: ShellConfig.px(configObject?.activationHeight ?? 20)
    property bool enableMouseHover: false
    property int iconHoveredIndex: -1

    Component.onCompleted: DesktopEntries.applications

    onIconHoveredIndexChanged: {
        Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'iconHoveredIndex=${iconHoveredIndex}' > /tmp/WayVes/dock`]);
    }

    property bool showScreencopy: configObject?.showPreviews ?? true

    readonly property var dockVisible: (hovered || iconHoveredIndex != -1 || workspaceIsEmpty || previewNotch.hovered || actionsNotch.hovered)

    Material.theme: Colors.isDark ? Material.Dark : Material.Light
    Material.accent: Colors.primary

    focusable: false
    color: "transparent"
    readonly property real layoutWidth: Quickshell.screens[0].width
    readonly property real layoutHeight: Quickshell.screens[0].height

    implicitHeight: Math.min(layoutHeight, ShellConfig.px(configObject?.surfaceHeight ?? 700))
    implicitWidth: layoutWidth
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dock"

    exclusionMode: PanelWindow.ExclusionMode.Ignore
    readonly property string historyPath: Quickshell.shellPath("persist/pinned_apps.json")

    function mapXRotatedPointToParent(tiltAngle, perspectiveDist, lx, ly, ox, oy) {
        let rad = tiltAngle * Math.PI / 180;

        let relX = lx - ox;
        let relY = ly - oy;

        let perspectiveDivisor = 1.0 - (relY * Math.sin(rad)) / perspectiveDist;

        let projX = ox + (relX / perspectiveDivisor);
        let projY = oy + ((relY * Math.cos(rad)) / perspectiveDivisor);

        return Qt.point(projX, projY);
    }

    function dockPoint(index, count, distance) {
        const step = count > 1 ? dock.dockConfig.viewSweepAngle / (count - 1) : 0;
        const angle = (index - (count - 1) / 2) * step * Math.PI / 180;
        const originX = dockPane.width / 2;
        const originY = dockPane.height;
        const mapped = mapXRotatedPointToParent(dock.dockConfig.viewTiltAngle, "distanceToPlane" in dockRotation ? dockRotation.distanceToPlane : 1024, originX + distance * Math.sin(angle), originY - distance * Math.cos(angle), originX, originY);
        return Qt.point(mapped.x, mapped.y - dockPane.height);
    }

    mask: rootRegion

    function getCombinedApps() {
        let apps = jsonAdapter.pinnedApps.map(app => ({
                    appId: app,
                    toplevelReferences: []
                }));

        for (let i = 0; i < ToplevelManager.toplevels.values.length; i++) {
            let top = ToplevelManager.toplevels.values[i];
            let id = top.appId;
            let filteredApps = apps.filter(app => app.appId == id);
            if (filteredApps.length == 0) {
                apps.push({
                    appId: top.appId,
                    toplevelReferences: [top]
                });
            } else
                filteredApps[0].toplevelReferences.push(top);
        }

        return apps;
    }

    Region {
        id: rootRegion
        Region {
            item: root.dockVisible ? iconsPane : null
        }
        Region {
            item: dockOverlay
        }
        Region {
            item: previewNotch.hovered ? previewNotch : null
        }
        Region {
            item: actionsNotch.hovered ? actionsNotch : null
        }
    }

    FileView {
        id: historyFile
        path: historyPath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: {
            writeAdapter();
        }
        adapter: JsonAdapter {
            id: jsonAdapter
            property var pinnedApps: []
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                jsonAdapter.pinnedApps = [];
                historyFile.writeAdapter();
            }
        }
    }

    Pane {
        id: dockOverlay
        opacity: root.opacity
        visible: root.opacity > 0.0
        enabled: visible
        width: root.dockVisible ? root.hoverWidth : root.activationWidth
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: root.dockVisible ? ShellConfig.px(20) + root.hoverHeight + dock.dockConfig.indicatorFloatHeight + dock.dockConfig.iconFloatHeight : root.activationHeight
        padding: 0
        background: Item {
            id: screenViewRow
            z: -1
            height: parent.height
            width: parent.width

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            HoverHandler {
                blocking: false
                onHoveredChanged: {
                    root.hovered = hovered;
                }
            }
        }

        ColumnLayout {
            id: dock
            property DockConfig dockConfig: DockConfig {
                configObject: root.configObject
            }

            height: parent.height
            width: root.layoutWidth

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            spacing: 0

            Pane {
                id: dockPane
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                padding: 0
                property var toplevelReferences: null
                property var captureSourceIndex: null
                transform: [
                    Rotation {
                        id: dockRotation
                        angle: dock.dockConfig.viewTiltAngle
                        axis {
                            x: 1
                            y: 0
                            z: 0
                        }
                        Component.onCompleted: {
                            if ("distanceToPlane" in dockRotation)
                                dockRotation.distanceToPlane = Qt.binding(() => dock.dockConfig.perspectiveDistance);
                        }
                        origin.y: dockPane.height
                        origin.x: dockPane.width / 2
                    }
                ]
                background: Rectangle {
                    color: "transparent"
                }

                Item {
                    id: testPane
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: root.layoutHeight / 2. - root.hoverHeight

                    implicitHeight: dock.dockConfig.radius
                    implicitWidth: dock.width

                    anchors.bottom: parent.bottom
                    transform: [
                        Translate {
                            y: (root.dockVisible) ? root.layoutHeight / 2. - root.hoverHeight : root.layoutHeight * 2 + dock.dockConfig.iconFloatHeight + dock.dockConfig.indicatorFloatHeight
                            Behavior on y {
                                NumberAnimation {
                                    id: offsetAnimation
                                    duration: 700
                                    easing.type: Easing.OutQuint
                                }
                            }
                        }
                    ]

                    Item {
                        id: dmabufDock
                        height: dock.dockConfig.radius
                        width: 2 * dock.dockConfig.radius
                        anchors.horizontalCenter: parent.horizontalCenter
                        Visualisers.Dock {
                            anchors.fill: parent
                            visible: root.dockVisible
                            active: root.dockVisible && root.opacity > 0
                        }

                        // Never shown; keeps the active indicator's WayVes instance running while the dock is up. Without it,
                        // focusing a window from an empty workspace woke a hidden (cleared) instance and the ring was blank for
                        // about a second, and an app switch could drop the count 1 -> 0 -> 1 and race the -v 0 / -v 1 commands.
                        Visualisers.AppIndicator {
                            isActive: true
                            visible: false
                            width: 1
                            height: 1
                            active: root.dockVisible && root.opacity > 0
                        }

                        anchors.bottom: parent.bottom
                    }
                    Item {
                        id: dockLayout
                        implicitHeight: dock.dockConfig.radius
                        implicitWidth: dock.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0.

                        property var combinedApps: root.getCombinedApps()
                        function sendElementCount() {
                            Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'numElements=${combinedApps?.length ?? 0}' > /tmp/WayVes/dock`]);
                        }
                        Component.onCompleted: sendElementCount()
                        onCombinedAppsChanged: {
                            sendElementCount();
                            dockPane.captureSourceIndex = null;
                            previewNotch.hovered = false;
                        }
                    }
                }
            }

            Pane {
                id: iconsPane
                padding: 0
                z: 2
                transform: [
                    Translate {

                        y: (root.dockVisible) ? 0 : root.implicitHeight
                        Behavior on y {
                            NumberAnimation {
                                id: offsetAnimation1
                                duration: 400
                                easing.type: Easing.OutQuint

                                onRunningChanged: {
                                    if (!running) {
                                        root.enableMouseHover = root.dockVisible;
                                        if (!root.dockVisible) {
                                            iconsPane.visible = false;
                                            dockPane.visible = false;
                                        }
                                    } else {
                                        if (root.dockVisible) {
                                            iconsPane.visible = true;
                                            dockPane.visible = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                ]

                Repeater {
                    id: appsRepeater
                    property var appModel: undefined
                    property int menuSelectedIndex: -1

                    model: dockLayout.combinedApps

                    delegate: Item {
                        id: innerColumnLayout
                        readonly property var focusedTopLevel: modelData.toplevelReferences.find(tlR => tlR.activated)

                        width: 0
                        height: 0
                        anchors.fill: parent
                        property var outerIndex: index

                        Item {
                            id: indicatorMapper
                            z: -1
                            width: 0
                            height: 0
                            readonly property point dockPosition: root.dockPoint(innerColumnLayout.outerIndex, dockLayout.combinedApps.length, dock.dockConfig.radius + dock.dockConfig.radialDisplacement + dock.dockConfig.indicatorDistance)
                            transform: [
                                Translate {
                                    x: indicatorMapper.dockPosition.x
                                    y: indicatorMapper.dockPosition.y
                                }
                            ]
                            Rectangle {
                                id: selectorHolder

                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "transparent"

                                width: dock.dockConfig.iconWidth
                                height: dock.dockConfig.iconHeight

                                property real indexFromCenter: index - (dockLayout.combinedApps.length - 1) / 2
                                property real fractionIndexFromCenter: indexFromCenter / dockLayout.combinedApps.length

                                property real angleFromCenter: (fractionIndexFromCenter) * dock.dockConfig.sweepAngle

                                Visualisers.AppIndicator {
                                    id: appSelector
                                    transform: Rotation {
                                        angle: index * 70
                                        origin.x: appSelector.width / 2.
                                        origin.y: appSelector.height / 2.
                                    }
                                    isActive: innerColumnLayout.focusedTopLevel != null
                                    width: dock.dockConfig.iconWidth * dock.dockConfig.indicatorWidthScale
                                    height: dock.dockConfig.iconHeight * dock.dockConfig.indicatorHeightScale
                                    anchors.centerIn: parent
                                    visible: modelData.toplevelReferences[0] != null && root.dockVisible

                                    active: root.dockVisible && root.opacity > 0
                                }
                                transform: [
                                    Rotation {

                                        angle: iconImage.angleFromCenter
                                        axis {
                                            x: (iconImage.verticalAngle / 90.)
                                            y: -Math.sign(iconImage.indexFromCenter)
                                            z: 0
                                        }
                                        origin.y: dock.dockConfig.iconHeight
                                        origin.x: dock.dockConfig.iconWidth / 2
                                    },
                                    Rotation {
                                        angle: iconImage.verticalAngle
                                        axis {
                                            x: 1
                                            y: -(iconImage.fractionIndexFromCenter)
                                            z: (iconImage.fractionIndexFromCenter)
                                        }
                                        origin.y: dock.dockConfig.iconHeight
                                        origin.x: dock.dockConfig.iconWidth / 2
                                    },
                                    Translate {
                                        y: -dock.dockConfig.indicatorFloatHeight - (root.iconHoveredIndex === index ? ShellConfig.px(12) : 0)
                                        Behavior on y {

                                            NumberAnimation {

                                                duration: 300
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                    }
                                ]
                            }
                        }

                        Item {
                            id: mapper

                            readonly property point dockPosition: root.dockPoint(innerColumnLayout.outerIndex, dockLayout.combinedApps.length, dock.dockConfig.radius + dock.dockConfig.radialDisplacement)
                            transform: [
                                Translate {
                                    id: iconTranslate
                                    x: mapper.dockPosition.x
                                    y: mapper.dockPosition.y
                                }
                            ]
                            Item {
                                id: iconClicksHandler
                                width: dock.dockConfig.iconWidth
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: dock.dockConfig.iconHeight
                                transform: [
                                    Translate {
                                        y: -dock.dockConfig.iconFloatHeight - dock.dockConfig.indicatorFloatHeight
                                    }
                                ]
                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                    blocking: false
                                    enabled: root.enableMouseHover
                                    onHoveredChanged: {
                                        if (hovered)
                                            root.iconHoveredIndex = index;
                                        else {
                                            root.iconHoveredIndex = -1;
                                        }
                                    }
                                }

                                TapHandler {
                                    onTapped: {
                                        actionsNotch.hovered = false;
                                        if (modelData && modelData.toplevelReferences != undefined && modelData.toplevelReferences.length > 0 && modelData.toplevelReferences[0] != null) {
                                            if (dockPane.captureSourceIndex == index) {
                                                previewNotch.hovered = true;
                                                previewNotch.hovered = true;
                                                return;
                                            }

                                            dockPane.captureSourceIndex = index;
                                            previewNotch.hovered = true;
                                            previewNotch.hovered = true;

                                            previewNotchTranslate.x = iconTranslate.x - root.layoutWidth / 2;
                                            previewNotchTranslate.y = iconTranslate.y - dock.dockConfig.iconFloatHeight - dock.dockConfig.indicatorFloatHeight - dock.dockConfig.iconHeight;
                                            dockPane.toplevelReferences = modelData.toplevelReferences;
                                            Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'iconClickedIndex=${index}' > /tmp/WayVes/dock`]);
                                        } else {
                                            DesktopEntries.heuristicLookup(modelData.appId)?.execute();
                                        }
                                    }
                                }

                                TapHandler {
                                    acceptedButtons: Qt.RightButton
                                    onTapped: {
                                        previewNotch.hovered = false;
                                        previewNotch.hovered = false;

                                        actionsNotchTranslate.x = iconTranslate.x - root.layoutWidth / 2;
                                        actionsNotchTranslate.y = iconTranslate.y - 20;
                                        actionsNotch.hovered = true;

                                        appsRepeater.menuSelectedIndex = index;
                                        appsRepeater.appModel = modelData;

                                        Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'iconClickedIndex=${index}' > /tmp/WayVes/dock`]);
                                    }
                                }
                            }
                            IconImage {
                                id: iconImage

                                property int radialDisplacement: ShellConfig.px(12)
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter

                                mipmap: true
                                source: {
                                    DesktopEntries.applications.values;
                                    return Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.appId)?.icon || modelData.appId.toLowerCase());
                                }
                                width: dock.dockConfig.iconWidth
                                height: dock.dockConfig.iconHeight
                                property real indexFromCenter: index - (Math.max(dockLayout.combinedApps.length, 1.) - 1) / 2
                                property real fractionIndexFromCenter: indexFromCenter / Math.max(dockLayout.combinedApps.length, 1.)

                                property real angleFromCenter: (fractionIndexFromCenter) * dock.dockConfig.sweepAngle
                                property real verticalAngle: dock.dockConfig.verticalAngle

                                Behavior on fractionIndexFromCenter {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutQuint
                                    }
                                }
                                Behavior on verticalAngle {

                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutQuint
                                    }
                                }

                                transform: [
                                    Rotation {

                                        angle: iconImage.angleFromCenter
                                        axis {
                                            x: (iconImage.verticalAngle / 90.)
                                            y: -Math.sign(iconImage.indexFromCenter)
                                            z: 0
                                        }
                                        origin.y: dock.dockConfig.iconHeight
                                        origin.x: dock.dockConfig.iconWidth / 2
                                    },
                                    Rotation {
                                        angle: iconImage.verticalAngle
                                        axis {
                                            x: 1
                                            y: -(iconImage.fractionIndexFromCenter)
                                            z: (iconImage.fractionIndexFromCenter)
                                        }
                                        origin.y: dock.dockConfig.iconHeight
                                        origin.x: dock.dockConfig.iconWidth / 2
                                    },
                                    Translate {
                                        y: -dock.dockConfig.iconFloatHeight - dock.dockConfig.indicatorFloatHeight - (root.iconHoveredIndex === index ? ShellConfig.px(20) : 0)
                                        Behavior on y {

                                            NumberAnimation {

                                                duration: 400
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: previewNotchHolder

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            transform: Translate {
                id: previewNotchTranslate
                x: 0
                y: 0
            }
            Notch {
                id: previewNotch

                clipContent: true
                transform: Translate {
                    id: notchTranslate
                    y: -previewNotch.notchHeight - ShellConfig.px(20)
                }

                anchors.horizontalCenter: parent.horizontalCenter
                configObject: root.configObject?.previewNotch
                visible: previewNotch.hovered

                direction: Directions.None

                onHoveredChanged: {
                    if (hovered) {
                        Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'iconClickedIndex=${dockPane.captureSourceIndex ?? -1}' > /tmp/WayVes/dock`]);
                        return;
                    }

                    Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'iconClickedIndex=-1' > /tmp/WayVes/dock`]);

                    if (!hovered) {
                        root.iconHoveredIndex = -1;
                        dockPane.toplevelReferences = null;
                        dockPane.captureSourceIndex = null;
                    }
                }

                panelContent: ListView {
                    clip: true
                    ScrollBar.horizontal: ScrollBar {
                        anchors.bottom: parent.bottom

                        policy: ScrollBar.AsNeeded
                        visible: root.showScreencopy
                        contentItem: Rectangle {
                            implicitWidth: ShellConfig.px(4)
                            radius: ShellConfig.px(20)
                            color: Colors.primary
                            opacity: 0.5
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        anchors.right: parent.right

                        policy: ScrollBar.AsNeeded
                        visible: !root.showScreencopy
                        contentItem: Rectangle {
                            implicitWidth: ShellConfig.px(4)
                            radius: ShellConfig.px(20)
                            color: Colors.primary
                            opacity: 0.5
                        }
                    }

                    property int numMaxChildren: root.configObject?.numMaxChildren ?? 2

                    implicitHeight: (root.showScreencopy) ? contentHeight : (Math.min(numMaxChildren, Math.max(1, dockPane.toplevelReferences?.length ?? 1)) * (contentHeight / Math.max(1, dockPane.toplevelReferences?.length ?? 1)))
                    implicitWidth: (!root.showScreencopy) ? contentWidth : (Math.min(numMaxChildren, Math.max(1, dockPane.toplevelReferences?.length ?? 1)) * (contentWidth / Math.max(1, dockPane.toplevelReferences?.length ?? 1)))

                    spacing: ShellConfig.px(24)
                    orientation: root.showScreencopy ? ListView.Horizontal : ListView.Vertical
                    model: dockPane.toplevelReferences

                    delegate: ColumnLayout {
                        spacing: root.showScreencopy ? ShellConfig.px(12) : 0

                        width: root.showScreencopy ? undefined : (parent.width - ShellConfig.px(24))
                        height: !root.showScreencopy ? childrenRect.height : (parent.height - ShellConfig.px(30))

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true

                            implicitHeight: childrenRect.height

                            spacing: ShellConfig.px(8)
                            Rectangle {
                                id: titleContainer

                                clip: true
                                implicitHeight: childrenRect.height
                                Layout.fillWidth: true

                                color: "transparent"

                                Rectangle {
                                    Layout.alignment: Qt.AlignRight
                                    width: parent.width
                                    implicitHeight: childrenRect.height
                                    color: root.showScreencopy ? Colors.surface_disabled : Colors.primary_container
                                    border.width: 1
                                    border.color: Colors.primary
                                    radius: ShellConfig.px(40)
                                    RoundButton {
                                        id: button
                                        enabled: !root.showScreencopy
                                        spacing: 0
                                        rightInset: 0
                                        leftInset: 0
                                        topInset: 0
                                        bottomInset: 0
                                        flat: true
                                        onClicked: {
                                            modelData.activate();
                                            previewNotch.hovered = false;
                                        }
                                        implicitWidth: parent.width
                                        contentItem: Text {
                                            id: titleText
                                            font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                                            text: modelData?.title
                                            color: Colors.on_primary_container

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
                                        HoverHandler {
                                            cursorShape: Qt.PointingHandCursor
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                width: ShellConfig.px(36)
                                height: ShellConfig.px(36)
                                color: Colors.surface_container
                                radius: ShellConfig.px(40)
                                border.width: 1
                                border.color: Colors.primary

                                Text {
                                    font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                                    transform: Translate {
                                        x: 0.5
                                        y: 1
                                    }
                                    text: ""
                                    color: Colors.on_surface
                                    anchors.centerIn: parent
                                }
                                HoverHandler {
                                    blocking: false

                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    cursorShape: Qt.PointingHandCursor

                                    onTapped: modelData.close()
                                }
                            }
                        }

                        Item {
                            Layout.preferredWidth: ShellConfig.px(root.configObject?.minimumToplevelWidth ?? 420)
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Loader {
                                active: root.showScreencopy

                                anchors.fill: parent

                                sourceComponent: Rectangle {
                                    id: sCVHolder
                                    radius: ShellConfig.px(20)
                                    visible: modelData != null && previewNotch.hovered
                                    implicitWidth: parent.width
                                    anchors.fill: parent
                                    border.width: 1
                                    border.color: "white"
                                    color: "#111111"

                                    ScreencopyView {
                                        id: screencopyView

                                        anchors.centerIn: parent
                                        live: true
                                        constraintSize: Qt.size(sCVHolder.width - 12, sCVHolder.height - 12)
                                        transform: Scale {
                                            origin.x: screencopyView.width / 2
                                            origin.y: screencopyView.height / 2
                                            xScale: sCVHolder.width / screencopyView.width
                                            yScale: sCVHolder.height / screencopyView.height
                                        }
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: sCVHolder.width
                                                height: sCVHolder.height
                                                radius: sCVHolder.radius
                                            }
                                        }
                                        captureSource: modelData
                                    }
                                    HoverHandler {
                                        blocking: false

                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    TapHandler {
                                        cursorShape: Qt.PointingHandCursor

                                        onTapped: {
                                            modelData.activate();
                                            previewNotch.hovered = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: actionsNotchHolder

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            transform: Translate {
                id: actionsNotchTranslate
                x: 0
                y: 0
            }
            Notch {
                id: actionsNotch
                z: -2
                anchors.horizontalCenter: parent.horizontalCenter

                transform: Translate {
                    y: -actionsNotch.notchHeight - dock.dockConfig.indicatorFloatHeight - dock.dockConfig.iconFloatHeight - dock.dockConfig.iconHeight
                }
                configObject: root.configObject?.menuNotch
                direction: Directions.None

                visible: hovered

                onHoveredChanged: {
                    if (hovered) {
                        Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'iconClickedIndex=${appsRepeater.menuSelectedIndex ?? -1}' > /tmp/WayVes/dock`]);
                        return;
                    }

                    Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'iconClickedIndex=-1' > /tmp/WayVes/dock`]);
                }

                panelContent: ColumnLayout {
                    spacing: ShellConfig.px(10)
                    Rectangle {
                        implicitHeight: childrenRect.height
                        implicitWidth: childrenRect.width
                        color: Colors.primary_container
                        radius: ShellConfig.px(40)

                        border.width: 1
                        border.color: Colors.outline
                        ScaledRoundButton {
                            readonly property bool isPinned: jsonAdapter.pinnedApps.some(pinnedApp => pinnedApp === appsRepeater.appModel?.appId)

                            text: isPinned ? "Unpin from Dock" : "Pin to Dock"
                            Material.theme: Colors.isDark ? Material.Dark : Material.Light
                            Material.accent: Colors.primary

                            topInset: 0
                            bottomInset: 0
                            leftInset: 0
                            rightInset: 0

                            flat: true

                            onClicked: {
                                if (isPinned) {
                                    jsonAdapter.pinnedApps = jsonAdapter.pinnedApps.filter(pinnedApp => pinnedApp != appsRepeater.appModel?.appId);
                                    historyFile.writeAdapter();
                                } else {
                                    jsonAdapter.pinnedApps.push(appsRepeater.appModel.appId);
                                    historyFile.writeAdapter();
                                }

                                actionsNotch.hovered = false;
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    Rectangle {
                        implicitHeight: childrenRect.height
                        implicitWidth: childrenRect.width
                        color: Colors.primary_container
                        visible: appsRepeater.appModel?.toplevelReferences.length > 0

                        border.width: 1
                        border.color: Colors.outline
                        radius: ShellConfig.px(40)
                        ScaledRoundButton {
                            text: "New Window"
                            Material.theme: Colors.isDark ? Material.Dark : Material.Light
                            Material.accent: Colors.primary

                            topInset: 0
                            bottomInset: 0
                            leftInset: 0
                            rightInset: 0

                            flat: true
                            onClicked: {
                                DesktopEntries.heuristicLookup(appsRepeater.appModel.appId)?.execute();
                                appsRepeater.appModel = undefined;
                                appsRepeater.menuSelectedIndex = -1;
                                actionsNotch.hovered = false;
                            }
                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            z: -3
            visible: root.configObject?.showHoverRegion ?? false
            color: 'red'
        }

        HoverHandler {
            blocking: false
            onHoveredChanged: {
                root.hovered = hovered;
            }
        }
    }
}
