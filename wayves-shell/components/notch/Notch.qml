import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

import qs.enums
import qs.config
import qs.config.theme

Item {
    id: root

    function mixColors(color1, color2, ratio) {
        var r = color1.r + (color2.r - color1.r) * ratio;
        var g = color1.g + (color2.g - color1.g) * ratio;
        var b = color1.b + (color2.b - color1.b) * ratio;
        var a = color1.a + (color2.a - color1.a) * ratio;
        return Qt.rgba(r, g, b, a);
    }

    property int direction: Directions.Down
    onDirectionChanged: generateRadiiBasedOnDirection()

    property var configObject: null

    property bool clipContent: false

    property real leftEdge: {
        if (topLeftRadius >= 0 && effectiveBottomLeftRadius >= 0)
            return 0;

        if (topLeftRadius < 0 && effectiveBottomLeftRadius < 0 && !flipTopLeft && effectiveFlipBottomLeft)
            return 0;

        if (topLeftRadius < 0 && effectiveBottomLeftRadius < 0 && flipTopLeft && !effectiveFlipBottomLeft)
            return Math.max(-topLeftRadius, -effectiveBottomLeftRadius);

        if (topLeftRadius < 0 && flipTopLeft)
            return -topLeftRadius;

        if (effectiveBottomLeftRadius < 0 && !effectiveFlipBottomLeft)
            return -effectiveBottomLeftRadius;

        return 0;
    }

    property real bottomEdge: {
        if (topLeftRadius >= 0 && topRightRadius >= 0)
            return notchHeight;

        if (topLeftRadius < 0 && topRightRadius < 0 && flipTopLeft && !flipTopRight)
            return notchHeight;

        if (topLeftRadius < 0 && topRightRadius < 0 && !flipTopLeft && flipTopRight)
            return notchHeight + Math.max(-topLeftRadius, -topRightRadius);

        if (topLeftRadius < 0 && !flipTopLeft)
            return notchHeight - topLeftRadius;

        if (topRightRadius < 0 && flipTopRight)
            return notchHeight - topRightRadius;

        return notchHeight;
    }

    property DropShadow dropShadow: DropShadow {
        enabled: configObject?.dropShadow?.enabled ?? false
        applyToShape: configObject?.dropShadow?.applyToShape ?? true

        leftExtent: ShellConfig.px(configObject?.dropShadow?.leftExtent ?? 30)
        rightExtent: ShellConfig.px(configObject?.dropShadow?.rightExtent ?? 30)
        topExtent: ShellConfig.px(configObject?.dropShadow?.topExtent ?? 30)
        bottomExtent: ShellConfig.px(configObject?.dropShadow?.bottomExtent ?? 30)

        verticalOffset: ShellConfig.px(configObject?.dropShadow?.verticalOffset ?? 8)
        horizontalOffset: ShellConfig.px(configObject?.dropShadow?.horizontalOffset ?? 0)

        blur: ShellConfig.px(configObject?.dropShadow?.blur ?? 32)
        spread: configObject?.dropShadow?.spread ?? 0

        color: configObject?.dropShadow?.color ?? Qt.tint(Qt.darker(Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 1), 3), Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, .5))
    }

    property NotchConfig notchConfig: NotchConfig {
        radius: ShellConfig.px(configObject?.radius ?? 28)
        minimumHeaderWidth: ShellConfig.pxOpt(configObject?.minimumHeaderWidth ?? -1)
        minimumHeaderHeight: ShellConfig.pxOpt(configObject?.minimumHeaderHeight ?? -1)

        headerLeftPadding: ShellConfig.pxOpt(configObject?.headerLeftPadding)
        headerRightPadding: ShellConfig.pxOpt(configObject?.headerRightPadding)
        headerTopPadding: ShellConfig.pxOpt(configObject?.headerTopPadding)
        headerBottomPadding: ShellConfig.pxOpt(configObject?.headerBottomPadding)

        headerHorizontalPadding: ShellConfig.pxOpt(configObject?.headerHorizontalPadding)
        headerVerticalPadding: ShellConfig.pxOpt(configObject?.headerVerticalPadding)

        headerPadding: ShellConfig.pxOpt(configObject?.headerPadding)

        minimumContentWidth: ShellConfig.pxOpt(configObject?.minimumContentWidth ?? -1)
        minimumContentHeight: ShellConfig.pxOpt(configObject?.minimumContentHeight ?? -1)

        contentLeftPadding: ShellConfig.pxOpt(configObject?.contentLeftPadding)
        contentRightPadding: ShellConfig.pxOpt(configObject?.contentRightPadding)
        contentTopPadding: ShellConfig.pxOpt(configObject?.contentTopPadding)
        contentBottomPadding: ShellConfig.pxOpt(configObject?.contentBottomPadding)

        contentHorizontalPadding: ShellConfig.pxOpt(configObject?.contentHorizontalPadding)
        contentVerticalPadding: ShellConfig.pxOpt(configObject?.contentVerticalPadding)

        contentPadding: ShellConfig.pxOpt(configObject?.contentPadding)
    }

    property var parentNotch: undefined
    property var backgroundShape: undefined

    property real notchWidth: 0
    property real notchHeight: 0

    property bool alwaysShowHeader: false

    readonly property var boundaryParent: findBoundaryParent(parent)
    property real panelOpacity: configObject?.panelOpacity ?? boundaryParent?.panelOpacity ?? ShellConfig.configObject?.notch?.panelOpacity ?? 0.65
    property color panelColor: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, panelOpacity)

    property bool childIsHovered: false
    property bool hovered: false
    property bool expanded: (childIsHovered || hovered) && panelContent != null

    readonly property bool showHeader: !expanded || alwaysShowHeader
    readonly property bool showContent: expanded

    readonly property ShapeConfig shapeConfig: ShapeConfig {
        notchWidth: root.notchWidth + root.leftSideOverflow + root.rightSideOverflow
        notchHeight: root.notchHeight + root.topSideOverflow + root.bottomSideOverflow + root.squashHeight

        topLeftRadius: root.topLeftRadius
        flipTopLeft: root.flipTopLeft

        topRightRadius: root.topRightRadius
        flipTopRight: root.flipTopRight

        bottomRightRadius: root.bottomRightRadius
        flipBottomRight: root.flipBottomRight

        bottomLeftRadius: root.effectiveBottomLeftRadius
        flipBottomLeft: root.effectiveFlipBottomLeft

        leftSideOverflow: root.leftSideOverflow
        rightSideOverflow: root.rightSideOverflow
        topSideOverflow: root.topSideOverflow
        bottomSideOverflow: root.bottomSideOverflow
    }

    onShowHeaderChanged: {
        root.notchWidth = contentHolder.implicitWidth;
        root.notchHeight = contentHolder.implicitHeight;
        generateRadiiBasedOnDirection();
    }
    onShowContentChanged: {
        root.notchWidth = contentHolder.implicitWidth;
        root.notchHeight = contentHolder.implicitHeight;
        generateRadiiBasedOnDirection();
    }

    property real overshoot: configObject?.overshoot ?? ShellConfig.configObject?.notch?.overshoot ?? 1

    Behavior on notchHeight {
        NumberAnimation {
            id: heightAnimation
            duration: root.overshoot > 0 ? 280 : 221
            easing.type: root.overshoot > 0 ? Easing.OutBack : Easing.OutBounce
            easing.overshoot: root.overshoot
        }
    }

    Behavior on notchWidth {
        NumberAnimation {
            id: widthAnimation
            duration: root.overshoot > 0 ? 280 : 220
            easing.type: root.overshoot > 0 ? Easing.OutBack : Easing.InOutCubic
            easing.overshoot: root.overshoot
        }
    }

    property real squash: ShellConfig.px(configObject?.squash ?? ShellConfig.configObject?.notch?.squash ?? 12)
    property real squashProgress: 0
    readonly property real squashHeight: squash * squashProgress

    SequentialAnimation {
        id: squashAnimation

        NumberAnimation {
            target: root
            property: "squashProgress"
            from: 0
            to: 1
            duration: widthAnimation.duration
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "squashProgress"
            to: 0
            duration: 260
            easing.type: Easing.OutBack
            easing.overshoot: 3
        }
    }

    onNotchWidthChanged: {
        syncRadiiWithDimensions();
        checkOverflow();
    }

    onNotchHeightChanged: {
        checkOverflow();
    }

    function syncRadiiWithDimensions() {
        let currentHeight = root.notchHeight;
        let currentWidth = root.notchWidth;

        if (root.topLeftRadius >= 0)
            root.topLeftRadius = Math.min(root.topLeftRadius, Math.min(currentHeight / 2., currentWidth / 2.));
        else if (root.flipTopLeft)
            root.topLeftRadius = -Math.min(-root.topLeftRadius, currentHeight / 2.);
        else
            root.topLeftRadius = -Math.min(-root.topLeftRadius, currentWidth / 2.);

        if (root.topRightRadius >= 0)
            root.topRightRadius = Math.min(root.topRightRadius, Math.min(currentHeight / 2., currentWidth / 2.));
        else if (root.flipTopRight)
            root.topRightRadius = -Math.min(-root.topRightRadius, currentWidth / 2.);
        else
            root.topRightRadius = -Math.min(-root.topRightRadius, currentHeight / 2.);

        if (root.bottomRightRadius >= 0)
            root.bottomRightRadius = Math.min(root.bottomRightRadius, Math.min(currentHeight / 2., currentWidth / 2.));
        else if (root.flipBottomRight)
            root.bottomRightRadius = -Math.min(-root.bottomRightRadius, currentHeight / 2.);
        else
            root.bottomRightRadius = -Math.min(-root.bottomRightRadius, currentWidth / 2.);

        if (root.bottomLeftRadius >= 0)
            root.bottomLeftRadius = Math.min(root.bottomLeftRadius, Math.min(currentHeight / 2., currentWidth / 2.));
        else if (root.flipBottomLeft)
            root.bottomLeftRadius = -Math.min(-root.bottomLeftRadius, currentWidth / 2.);
        else
            root.bottomLeftRadius = -Math.min(-root.bottomLeftRadius, currentHeight / 2.);
    }

    property Component headerContent: Item {}
    property Component panelContent: null
    property bool preloadContent: false
    property bool warmingContent: preloadContent

    readonly property real usedRadius: Math.min(notchConfig.radius, Math.min(notchWidth / 2., notchHeight / 2.))

    property real topLeftRadius: -usedRadius
    property bool flipTopLeft: true

    property real topRightRadius: -usedRadius
    property bool flipTopRight: false

    property real bottomRightRadius: -usedRadius
    property bool flipBottomRight: false

    property real bottomLeftRadius: usedRadius
    property bool flipBottomLeft: false

    property Item bottomLeftClaimant: null
    property real claimedBottomLeftRadius: 0
    property bool claimedFlipBottomLeft: false

    readonly property bool bottomLeftClaimed: bottomLeftClaimant !== null && expanded
    readonly property real effectiveBottomLeftRadius: bottomLeftClaimed ? claimedBottomLeftRadius : bottomLeftRadius
    readonly property bool effectiveFlipBottomLeft: bottomLeftClaimed ? claimedFlipBottomLeft : flipBottomLeft

    function claimBottomLeft(claimant, radius, flip) {
        if (bottomLeftClaimant === claimant && Math.abs(claimedBottomLeftRadius - radius) <= 0.01 && claimedFlipBottomLeft === flip)
            return;
        bottomLeftClaimant = claimant;
        claimedBottomLeftRadius = radius;
        claimedFlipBottomLeft = flip;
    }

    function releaseBottomLeft(claimant) {
        if (bottomLeftClaimant === claimant)
            bottomLeftClaimant = null;
    }

    Component.onDestruction: {
        let panelParent = findBoundaryParent(root.parent);
        if (panelParent)
            panelParent.releaseBottomLeft(root);
    }

    property real leftSideOverflow: root.getLeftSideOverflow()
    property real rightSideOverflow: root.getRightSideOverflow()
    property real topSideOverflow: root.getTopSideOverflow()
    property real bottomSideOverflow: root.getBottomSideOverflow()
    property bool checkParentBottomLeftOverflow: false

    width: root.notchWidth + root.leftSideOverflow + root.rightSideOverflow
    height: root.notchHeight + root.topSideOverflow + root.bottomSideOverflow

    Component.onCompleted: {
        root.notchWidth = contentHolder.implicitWidth;
        root.notchHeight = contentHolder.implicitHeight;

        generateRadiiBasedOnDirection();
        updateWindowPosition();

        let cp = getCustomParent(root);
        if (cp) {
            root.parentNotch = cp;
            root.dropShadow.enabled = cp.dropShadow.enabled && !cp.dropShadow.applyToShape ? false : root.dropShadow.enabled;
        }
    }

    function getCustomParent(item) {
        let p = item.parent;
        while (p) {
            if (p.hasOwnProperty("childIsHovered"))
                return p;
            p = p.parent;
        }
        return null;
    }

    function findBoundaryParent(item) {
        if (!item)
            return null;
        if (item.hasOwnProperty("childIsHovered"))
            return item;
        return findBoundaryParent(item.parent);
    }

    function checkOverflow() {
        if (!checkParentBottomLeftOverflow)
            return;

        let panelParent = findBoundaryParent(root.parent);

        if (!panelParent)
            return;

        let parentBottom = panelParent.mapToGlobal(0, 0).y + panelParent.height - panelParent.bottomSideOverflow;
        let childBottom = root.mapToGlobal(0, 0).y + root.height - root.bottomSideOverflow;
        let difference = parentBottom - childBottom;

        let setBottomRight = radius => {
            if (Math.abs(root.bottomRightRadius - radius) > 0.01)
                root.bottomRightRadius = radius;
        };

        if (!panelParent.expanded || !root.expanded) {
            panelParent.releaseBottomLeft(root);
            setBottomRight(-root.usedRadius);
            return;
        }
        if (difference < 0) {
            setBottomRight(Math.min((-difference / 2.), root.usedRadius));
            panelParent.claimBottomLeft(root, -Math.min((-difference / 2.), panelParent.usedRadius), true);
        } else {
            setBottomRight(-Math.min((difference / 2.), root.usedRadius));
            panelParent.claimBottomLeft(root, Math.min((difference / 2.), panelParent.usedRadius), true);
            root.flipBottomRight = false;
        }
    }

    readonly property real devicePixelRatio: Window.window?.devicePixelRatio ?? 1
    readonly property real pixelScaleX: Window.window && Window.window.width > 0 ? Math.round(Window.window.width * devicePixelRatio) / Window.window.width : devicePixelRatio
    readonly property real pixelScaleY: Window.window && Window.window.height > 0 ? Math.round(Window.window.height * devicePixelRatio) / Window.window.height : devicePixelRatio
    property point windowPosition: Qt.point(0, 0)

    function updateWindowPosition() {
        let p = root.mapToItem(null, 0, 0);
        if (p.x !== windowPosition.x || p.y !== windowPosition.y)
            windowPosition = p;
    }

    onXChanged: updateWindowPosition()
    onYChanged: updateWindowPosition()
    onWidthChanged: updateWindowPosition()
    onHeightChanged: updateWindowPosition()

    Connections {
        target: root.Window.window
        function onAfterAnimating() {
            root.updateWindowPosition();
            root.checkOverflow();
        }
    }

    onUsedRadiusChanged: {
        generateRadiiBasedOnDirection();
    }

    onExpandedChanged: {
        let cp = getCustomParent(root);
        if (cp) {
            cp.childIsHovered = root.expanded;
        }
        if (!root.expanded && root.squash > 0)
            squashAnimation.restart();
    }

    function generateRadiiBasedOnDirection() {
        root.topLeftRadius = Math.abs(root.usedRadius);
        root.topRightRadius = Math.abs(root.usedRadius);
        root.bottomRightRadius = Math.abs(root.usedRadius);
        root.bottomLeftRadius = Math.abs(root.usedRadius);

        if (root.direction === Directions.None)
            return;

        var topLeftTracker = undefined;
        var topRightTracker = undefined;
        var bottomLeftTracker = undefined;
        var bottomRightTracker = undefined;

        if (root.direction & Directions.Right) {
            root.topLeftRadius = -root.usedRadius;
            topLeftTracker = (topLeftTracker ?? 0) - 1;

            root.bottomLeftRadius = -root.usedRadius;
            bottomLeftTracker = (bottomLeftTracker ?? 0) + 1;
        }

        if (root.direction & Directions.Left) {
            root.topRightRadius = -root.usedRadius;
            topRightTracker = (topRightTracker ?? 0) + 1;

            root.bottomRightRadius = -root.usedRadius;
            bottomRightTracker = (bottomRightTracker ?? 0) - 1;
        }

        if (root.direction & Directions.Up) {
            root.bottomRightRadius = -root.usedRadius;
            bottomRightTracker = (bottomRightTracker ?? 0) + 1;

            root.bottomLeftRadius = -root.usedRadius;
            bottomLeftTracker = (bottomLeftTracker ?? 0) - 1;
        }

        if (root.direction & Directions.Down) {
            root.topLeftRadius = -root.usedRadius;
            topLeftTracker = (topLeftTracker ?? 0) + 1;

            root.topRightRadius = -root.usedRadius;
            topRightTracker = (topRightTracker ?? 0) - 1;
        }

        root.flipTopLeft = topLeftTracker >= 0;
        root.flipTopRight = topRightTracker >= 0;
        root.flipBottomLeft = bottomLeftTracker >= 0;
        root.flipBottomRight = bottomRightTracker >= 0;

        root.topLeftRadius = topLeftTracker === 0 ? 0 : root.topLeftRadius;
        root.topRightRadius = topRightTracker === 0 ? 0 : root.topRightRadius;
        root.bottomRightRadius = bottomRightTracker === 0 ? 0 : root.bottomRightRadius;
        root.bottomLeftRadius = bottomLeftTracker === 0 ? 0 : root.bottomLeftRadius;
    }

    function getRightSideOverflow() {
        let overflow = 0;

        if (root.topRightRadius < 0 && !root.flipTopRight)
            overflow = -root.topRightRadius;

        if (root.bottomRightRadius < 0 && root.flipBottomRight)
            overflow = Math.max(overflow, -root.bottomRightRadius);

        return overflow;
    }

    function getLeftSideOverflow() {
        let overflow = 0;

        if (root.effectiveBottomLeftRadius < 0 && !root.effectiveFlipBottomLeft)
            overflow = -root.effectiveBottomLeftRadius;

        if (root.topLeftRadius < 0 && root.flipTopLeft)
            overflow = Math.max(overflow, -root.topLeftRadius);

        return overflow;
    }

    function getBottomSideOverflow() {
        let overflow = 0;

        if (root.bottomRightRadius < 0 && !root.flipBottomRight)
            overflow = -root.bottomRightRadius;

        if (root.effectiveBottomLeftRadius < 0 && root.effectiveFlipBottomLeft)
            overflow = Math.max(overflow, -root.effectiveBottomLeftRadius);

        return overflow;
    }

    function getTopSideOverflow() {
        let overflow = 0;

        if (root.topLeftRadius < 0 && !root.flipTopLeft)
            overflow = -root.topLeftRadius;

        if (root.topRightRadius < 0 && root.flipTopRight)
            overflow = Math.max(overflow, -root.topRightRadius);

        return overflow;
    }

    Loader {
        id: shadowLoader
        visible: active
        asynchronous: true
        active: !root.dropShadow.applyToShape && root.dropShadow.enabled
        onActiveChanged: {
            if (!active)
                contentsItem.parent = shadowLoader.parent;
        }
        sourceComponent: ShadowRenderer {
            id: shadowRenderer1
            dropShadow: root.dropShadow
            contentItem: contentsItem
        }
    }

    Item {
        id: contentsItem
        width: childrenRect.width
        height: childrenRect.height

        property point currentPoint: Qt.point(0, 0)
        Component.onCompleted: root.backgroundShape = notchShapeHolder

        Item {
            id: notchShapeHolder

            width: notchShape.width
            height: notchShape.height

            NotchShapePainter {
                id: notchShape

                transform: Translate {
                    id: translate
                    y: root.direction & Directions.Down ? 0 : root.direction & Directions.Up ? -root.squashHeight : -root.squashHeight / 2
                }
                fillColor: root.panelColor

                shapeConfig: root.shapeConfig
                windowPosition: root.windowPosition
                pixelScaleX: root.pixelScaleX
                pixelScaleY: root.pixelScaleY
            }

            Loader {
                id: shapeShadowLoader
                asynchronous: true

                active: root.dropShadow.applyToShape && root.dropShadow.enabled
                visible: active
                onActiveChanged: {
                    if (!active)
                        notchShape.parent = shapeShadowLoader.parent;
                }

                sourceComponent: ShadowRenderer {
                    id: shadowRenderer

                    dropShadow: root.dropShadow
                    contentItem: notchShape
                }
            }
        }

        Rectangle {
            id: contentHolder
            implicitWidth: (((root.showHeader ? Math.max(headerPane.implicitWidth, root.notchConfig.minimumHeaderWidth) : 0) + (root.showContent ? Math.max(contentPane.implicitWidth, root.notchConfig.minimumContentWidth) : 0)))
            implicitHeight: (((root.showHeader ? Math.max(headerPane.implicitHeight, root.notchConfig.minimumHeaderHeight) : 0) + (root.showContent ? Math.max(contentPane.implicitHeight, root.notchConfig.minimumContentHeight) : 0)))

            onImplicitWidthChanged: {
                root.notchWidth = implicitWidth;
            }
            onImplicitHeightChanged: {
                root.notchHeight = implicitHeight;
            }

            transform: Translate {
                x: root.leftSideOverflow
                y: root.topSideOverflow
            }

            color: 'transparent'

            ColumnLayout {
                id: columnLayout

                anchors.fill: parent
                anchors.centerIn: parent
                spacing: 0

                Pane {
                    id: headerPane

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    readonly property real preferredWidth: root.showHeader ? (root.notchConfig.minimumHeaderWidth) : 0
                    readonly property real preferredHeight: root.showHeader ? (root.notchConfig.minimumHeaderHeight) : 0

                    Layout.preferredWidth: preferredWidth
                    Layout.preferredHeight: preferredHeight

                    visible: root.showHeader

                    background: Item {}

                    topPadding: root.notchConfig.headerTopPadding
                    bottomPadding: root.notchConfig.headerBottomPadding
                    leftPadding: root.notchConfig.headerLeftPadding
                    rightPadding: root.notchConfig.headerRightPadding
                    verticalPadding: root.notchConfig.headerVerticalPadding
                    horizontalPadding: root.notchConfig.headerHorizontalPadding
                    padding: root.notchConfig.headerPadding

                    Loader {
                        id: headerLoader
                        anchors.fill: parent
                        active: root.showHeader
                        visible: active

                        sourceComponent: root.headerContent
                    }
                }
                Pane {
                    id: contentPane
                    Layout.margins: 0

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property real preferredHeight: root.showContent ? root.notchConfig.minimumContentHeight : 0
                    property real preferredWidth: root.showContent ? root.notchConfig.minimumContentWidth : 0

                    Layout.preferredHeight: preferredHeight
                    Layout.preferredWidth: preferredWidth

                    visible: root.showContent
                    background: Item {}

                    topPadding: root.notchConfig.contentTopPadding
                    bottomPadding: root.notchConfig.contentBottomPadding
                    leftPadding: root.notchConfig.contentLeftPadding
                    rightPadding: root.notchConfig.contentRightPadding
                    verticalPadding: root.notchConfig.contentVerticalPadding
                    horizontalPadding: root.notchConfig.contentHorizontalPadding
                    padding: root.notchConfig.contentPadding

                    Loader {
                        id: contentLoader
                        active: root.warmingContent || root.showContent
                        asynchronous: root.warmingContent
                        visible: root.showContent
                        onLoaded: if (root.warmingContent)
                            Qt.callLater(() => root.warmingContent = false)
                        anchors.fill: parent

                        sourceComponent: root.panelContent
                    }
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        blocking: false
        margin: ShellConfig.px(12)
        onHoveredChanged: {
            if (enabled)
                root.hovered = hovered;
        }
    }

    component NotchShapePainter: Item {
        id: root

        property color fillColor: "transparent"
        property color strokeColor: fillColor

        property ShapeConfig shapeConfig

        readonly property real bodyWidth: Math.max(topWidth - leftEdge, 0)
        readonly property real bodyHeight: Math.max(rightHeight - topEdge, 0)
        readonly property real maxRadius: Math.min(bodyWidth, bodyHeight) / 2.

        function clampRadius(radius) {
            return Math.sign(radius) * Math.min(Math.abs(radius), maxRadius);
        }

        readonly property real topLeftRadius: clampRadius(shapeConfig.topLeftRadius)
        readonly property real topRightRadius: clampRadius(shapeConfig.topRightRadius)
        readonly property real bottomRightRadius: clampRadius(shapeConfig.bottomRightRadius)
        readonly property real bottomLeftRadius: clampRadius(shapeConfig.bottomLeftRadius)

        property point windowPosition: Qt.point(0, 0)
        property real pixelScaleX: 1
        property real pixelScaleY: 1

        function snapX(value) {
            return Math.round((windowPosition.x + value) * pixelScaleX) / pixelScaleX - windowPosition.x;
        }
        function snapY(value) {
            return Math.round((windowPosition.y + value) * pixelScaleY) / pixelScaleY - windowPosition.y;
        }

        readonly property real leftEdge: snapX(root.shapeConfig.leftSideOverflow + shapePath.roundedHalfStrokeWidth)
        readonly property real topEdge: snapY(root.shapeConfig.topSideOverflow + shapePath.roundedHalfStrokeWidth)

        readonly property real bottomWidth: snapX(Math.max(root.shapeConfig.notchWidth - root.shapeConfig.rightSideOverflow - shapePath.roundedHalfStrokeWidth, 0))
        readonly property real topWidth: snapX(Math.max(root.shapeConfig.notchWidth - root.shapeConfig.rightSideOverflow - shapePath.roundedHalfStrokeWidth, 0))
        readonly property real leftHeight: snapY(Math.max(root.shapeConfig.notchHeight - root.shapeConfig.bottomSideOverflow - shapePath.roundedHalfStrokeWidth, 0))
        readonly property real rightHeight: snapY(Math.max(root.shapeConfig.notchHeight - root.shapeConfig.bottomSideOverflow - shapePath.roundedHalfStrokeWidth, 0))

        width: shapeConfig.notchWidth
        height: shapeConfig.notchHeight

        Shape {
            id: notchShape

            preferredRendererType: Shape.CurveRenderer
            anchors.fill: parent
            antialiasing: true
            layer.enabled: false
            ShapePath {
                id: shapePath

                readonly property real roundedHalfStrokeWidth: Math.floor(strokeWidth / 2 + .5)
                asynchronous: false
                strokeColor: "white"
                strokeWidth: 0
                fillColor: root.fillColor
                capStyle: ShapePath.RoundCap
                startX: root.leftEdge
                startY: root.topEdge

                PathMove {
                    x: shapePath.startX + (!root.shapeConfig.flipTopLeft && root.topLeftRadius < 0 ? -1 : 1) * root.topLeftRadius
                    y: shapePath.startY
                }
                PathLine {
                    x: root.topWidth - Math.abs(root.topRightRadius)
                    y: shapePath.startY
                }

                ArcGetter {
                    radius: root.topRightRadius
                    incomingPoint: Qt.point(root.topWidth - (Math.abs(root.topRightRadius)), (shapePath.startY))
                    incomingDirection: Directions.Right
                    flipNegativeRadiusFromIncomingDirection: root.shapeConfig.flipTopRight
                }

                PathLine {
                    x: root.topWidth
                    y: root.rightHeight - Math.abs(root.bottomRightRadius)
                }

                ArcGetter {
                    radius: root.bottomRightRadius
                    incomingPoint: Qt.point(root.topWidth, root.rightHeight - (Math.abs(root.bottomRightRadius)))
                    incomingDirection: Directions.Down
                    flipNegativeRadiusFromIncomingDirection: root.shapeConfig.flipBottomRight
                }

                PathLine {
                    x: Math.abs(root.bottomLeftRadius) + (shapePath.startX)
                    y: root.rightHeight
                }

                ArcGetter {
                    radius: root.bottomLeftRadius
                    incomingPoint: Qt.point((Math.abs(root.bottomLeftRadius)) + (shapePath.startX), root.leftHeight)
                    incomingDirection: Directions.Left
                    flipNegativeRadiusFromIncomingDirection: root.shapeConfig.flipBottomLeft
                }

                PathLine {
                    x: (shapePath.startX)
                    y: Math.abs(root.topLeftRadius) + (shapePath.startY)
                }

                ArcGetter {
                    radius: root.topLeftRadius
                    incomingPoint: Qt.point((shapePath.startX), Math.abs(root.topLeftRadius) + (shapePath.startY))
                    incomingDirection: Directions.Up
                    flipNegativeRadiusFromIncomingDirection: root.shapeConfig.flipTopLeft
                }
            }
        }
    }

    component ArcGetter: PathAngleArc {
        id: root

        property real radius: 0
        property int incomingDirection: Directions.Right
        property bool flipNegativeRadiusFromIncomingDirection: false

        property point incomingPoint: Qt.point(0, 0)
        readonly property bool flippedOrPositiveRadius: root.radius >= 0 || root.flipNegativeRadiusFromIncomingDirection

        function getCenterX() {
            switch (root.incomingDirection) {
            case Directions.Right:
                {
                    return root.incomingPoint.x - (root.flippedOrPositiveRadius ? 0 : 2 * root.radius);
                }
            case Directions.Left:
                {
                    return root.incomingPoint.x + (root.flippedOrPositiveRadius ? 0 : 2 * root.radius);
                }
            case Directions.Up:
                {
                    return root.incomingPoint.x - (root.flippedOrPositiveRadius ? -1 : 1) * root.radius;
                }
            case Directions.Down:
                {
                    return root.incomingPoint.x + (root.flippedOrPositiveRadius ? -1 : 1) * root.radius;
                }
            default:
                {
                    return 0;
                }
            }
        }

        function getCenterY() {
            switch (root.incomingDirection) {
            case Directions.Right:
                {
                    return root.incomingPoint.y + (root.flippedOrPositiveRadius ? 1 : -1) * root.radius;
                }
            case Directions.Left:
                {
                    return root.incomingPoint.y - (root.flippedOrPositiveRadius ? 1 : -1) * root.radius;
                }
            case Directions.Up:
                {
                    return root.incomingPoint.y + (root.flippedOrPositiveRadius ? 0 : 2 * root.radius);
                }
            case Directions.Down:
                {
                    return root.incomingPoint.y - (root.flippedOrPositiveRadius ? 0 : 2 * root.radius);
                }
            default:
                {
                    return 0;
                }
            }
        }

        function getStartAngle() {
            switch (root.incomingDirection) {
            case Directions.Right:
                {
                    return (root.radius >= 0 || !root.flipNegativeRadiusFromIncomingDirection ? -1 : 1) * 90;
                }
            case Directions.Left:
                {
                    return (root.radius >= 0 || !root.flipNegativeRadiusFromIncomingDirection ? 1 : -1) * 90;
                }
            case Directions.Up:
                {
                    return (root.radius >= 0 || !root.flipNegativeRadiusFromIncomingDirection ? 180 : 0);
                }
            case Directions.Down:
                {
                    return (root.radius >= 0 || !root.flipNegativeRadiusFromIncomingDirection ? 0 : 180);
                }
            default:
                {
                    return 0;
                }
            }
        }

        centerX: getCenterX()
        centerY: getCenterY()
        radiusX: Math.abs(root.radius)
        radiusY: Math.abs(root.radius)
        startAngle: getStartAngle()
        sweepAngle: Math.sign(root.radius) * 90
        moveToStart: false
    }

    component ShadowRenderer: Item {
        id: root
        property real radius: 0
        property DropShadow dropShadow: DropShadow {}
        readonly property bool applyShadow: dropShadow.enabled

        readonly property real leftExtent: dropShadow.leftExtent
        readonly property real rightExtent: dropShadow.rightExtent

        readonly property real topExtent: dropShadow.topExtent
        readonly property real bottomExtent: dropShadow.bottomExtent

        implicitWidth: sourceItem.width
        implicitHeight: sourceItem.height

        property alias contentItem: sourceItem.children
        transform: [
            Translate {
                x: (root.applyShadow ? -root.leftExtent : 0)

                y: (root.applyShadow ? -root.topExtent : 0)
            }
        ]

        Item {
            id: sourceRect

            anchors.top: parent.top
            anchors.left: parent.left

            z: 1
            implicitWidth: sourceItem.width + (root.applyShadow ? (root.leftExtent + root.rightExtent) : 0)
            implicitHeight: sourceItem.height + (root.applyShadow ? (root.topExtent + root.bottomExtent) : 0)
            Item {
                id: sourceItem
                transform: Translate {
                    x: root.applyShadow ? root.leftExtent : 0
                    y: root.applyShadow ? root.topExtent : 0
                }

                width: childrenRect.width
                height: childrenRect.height
            }
        }

        ShaderEffectSource {
            id: sourceTexture
            anchors.fill: sourceRect
            sourceItem: root.applyShadow ? sourceRect : null
            hideSource: false
            live: true
            visible: false
        }

        Item {
            id: maskItem
            anchors.centerIn: parent
            layer.enabled: root.applyShadow
            layer.live: false
            visible: false
            anchors.fill: parent

            Rectangle {
                anchors.centerIn: parent

                anchors.fill: parent
                color: Qt.rgba(1, 1, 1)
            }
        }

        MultiEffect {
            id: cutoutEffect
            layer.enabled: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            visible: false
            anchors.fill: sourceRect
            source: sourceTexture
            maskSource: maskItem
            maskEnabled: root.applyShadow
        }

        MultiEffect {
            id: cutoutEffect2
            visible: root.applyShadow
            anchors.fill: cutoutEffect
            anchors.top: parent.top

            source: cutoutEffect
            maskSource: sourceTexture
            maskEnabled: root.applyShadow
            maskInverted: true
            anchors.horizontalCenter: parent.horizontalCenter

            shadowEnabled: root.applyShadow
            shadowBlur: 1
            blurMax: Math.round(root.dropShadow.blur)
            shadowScale: 1 + root.dropShadow.spread
            shadowVerticalOffset: root.dropShadow.verticalOffset
            shadowHorizontalOffset: root.dropShadow.horizontalOffset
            autoPaddingEnabled: false

            shadowColor: root.dropShadow.color
        }
    }
}
