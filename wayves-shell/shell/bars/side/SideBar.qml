import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.config
import qs.enums
import qs.components.notch
import qs.config.theme
import qs.Visualisers

ShellRoot {
    id: shellRoot
    property var visible: true

    property bool allowHover: true
    property var configObject: undefined

    PanelWindow {
        id: root

        anchors.right: true
        anchors.top: true
        visible: shellRoot.visible

        property bool hovered: false

        margins.top: root.screen ? Math.max(0, Math.min(ShellConfig.px(250), Math.floor((root.screen.height - root.implicitHeight) / 2))) : ShellConfig.px(250)

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "side-bar"
        WlrLayershell.layer: WlrLayer.Top
        property real gpuNotchBottom: 0
        implicitHeight: Math.max(ShellConfig.px(1000), Math.ceil(rightNotch.height), Math.ceil(gpuNotchBottom))
        implicitWidth: ShellConfig.px(1000)

        focusable: true

        color: "transparent"

        property var extraRects: []
        property bool useMask: true
        mask: useMask ? rootRegion : null

        Process {
            id: gpuNameProcess
            property string text: ""
            running: true

            command: ["sh", "-c", Quickshell.shellDir + "/scripts/gpu/name.sh"]
            stdout: SplitParser {
                onRead: data => {
                    gpuNameProcess.text = data;
                }
            }
        }

        Process {
            id: gpuStatsProcess
            property var temp: 0
            property var freq: 0
            property var memory: 0
            property var usage: 0
            running: root.hovered

            command: ["sh", "-c", Quickshell.shellDir + "/scripts/gpu/stats.sh"]
            stdout: SplitParser {
                onRead: data => {
                    const [temp, freq, memory, usage] = data.split(" ");
                    gpuStatsProcess.temp = temp;
                    gpuStatsProcess.freq = freq;
                    gpuStatsProcess.memory = memory;
                    gpuStatsProcess.usage = usage;
                }
            }
        }

        Process {
            id: cpuTempProcess
            property var text: 0
            running: root.hovered

            command: ["sh", "-c", Quickshell.shellDir + "/scripts/cpu/temp.sh"]
            stdout: SplitParser {
                onRead: data => {
                    cpuTempProcess.text = data;
                }
            }
        }

        Process {
            id: memoryUsageProcess
            property var used: 0
            property var total: 0
            running: root.hovered

            command: ["sh", "-c", Quickshell.shellDir + "/scripts/ram/usage.sh"]
            stdout: SplitParser {
                onRead: data => {
                    memoryUsageProcess.used = data.split(" ")[0];
                    memoryUsageProcess.total = data.split(" ")[1];
                }
            }
        }

        Process {
            id: cpuUsageProcess
            property var text: 0
            running: root.hovered

            command: ["sh", "-c", Quickshell.shellDir + "/scripts/cpu/usage.sh"]
            stdout: SplitParser {
                onRead: data => {
                    cpuUsageProcess.text = data;
                }
            }
        }

        Region {
            id: rootRegion
            item: sideBarHoverHandle
        }

        Item {
            anchors.fill: parent
            anchors.right: parent.right

            RowLayout {
                id: bar
                transform: [
                    Translate {
                        x: (root.hovered) ? 0 : root.implicitWidth
                        Behavior on x {
                            NumberAnimation {
                                id: offsetAnimation
                                duration: 300
                                easing.type: Easing.OutQuint
                            }
                        }
                    }
                ]
                anchors.right: parent.right

                Item {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillHeight: true
                    Notch {
                        id: rightNotch
                        anchors.right: parent.right

                        configObject: shellRoot.configObject?.rightNotch
                        direction: Directions.Left

                        headerContent: ColumnLayout {
                            spacing: ShellConfig.px(20)
                            anchors.fill: parent
                            anchors.horizontalCenter: parent.horizontalCenter
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "CPU Usage"
                                color: Colors.on_surface
                                font.pixelSize: ShellConfig.fontPx(28)
                                Layout.bottomMargin: ShellConfig.px(20)
                            }

                            Rectangle {
                                id: cpuUsagePlaceHolder
                                implicitWidth: ShellConfig.px(260)
                                implicitHeight: ShellConfig.px(260)
                                color: "transparent"
                                Layout.alignment: Qt.AlignHCenter

                                Visualisers.Usage {
                                    purpose: "cpu_usage"
                                    active: root.hovered
                                    visible: root.hovered
                                    anchors.fill: parent
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: cpuUsageProcess.text + "%"
                                    font.pixelSize: ShellConfig.fontPx(20)
                                    color: Colors.on_surface
                                }
                            }
                            Item {
                                Layout.fillHeight: true
                            }
                            Item {
                                id: leftNotchHolder
                                Layout.fillHeight: true
                                Layout.leftMargin: ShellConfig.px(-40)
                                Layout.topMargin: ShellConfig.px(-290)
                                Layout.alignment: Qt.AlignLeft
                                Notch {
                                    id: memoryNotch
                                    anchors.right: parent.right
                                    direction: Directions.Left

                                    configObject: shellRoot.configObject?.topNotch

                                    headerContent: ColumnLayout {
                                        spacing: ShellConfig.px(20)
                                        Text {
                                            Layout.topMargin: ShellConfig.px(20)
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "Memory"
                                            color: Colors.on_surface
                                            font.pixelSize: ShellConfig.fontPx(28)
                                        }

                                        Rectangle {
                                            id: memoryUsagePlaceHolder
                                            implicitWidth: ShellConfig.px(150)
                                            implicitHeight: ShellConfig.px(150)
                                            color: "transparent"
                                            Layout.alignment: Qt.AlignHCenter

                                            Visualisers.Usage {
                                                purpose: "memory_usage"
                                                active: root.hovered
                                                visible: root.hovered
                                                anchors.fill: parent
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: (memoryUsageProcess.used / memoryUsageProcess.total * 100).toFixed(1) + "%"
                                                font.pixelSize: ShellConfig.fontPx(20)
                                                color: Colors.on_surface
                                            }
                                        }

                                        TextResourceInformation {
                                            prefix: "Used"
                                            reading: memoryUsageProcess.used > 1024 ? (memoryUsageProcess.used / 1024).toFixed(1) : memoryUsageProcess.used
                                            suffix: memoryUsageProcess.used > 1024 ? " GB" : " MB"
                                            tagColor: "transparent"
                                            horizontalMargin: 20
                                            Layout.bottomMargin: ShellConfig.px(-20)
                                            Layout.topMargin: ShellConfig.px(20)
                                        }

                                        Notch {
                                            id: gpuNotch
                                            configObject: shellRoot.configObject?.bottomNotch

                                            readonly property real bodyHeight: gpuNotch.notchHeight + gpuNotch.topSideOverflow + gpuNotch.bottomSideOverflow
                                            readonly property real parentBottomPadding: memoryNotch.notchConfig.headerBottomPadding ?? memoryNotch.notchConfig.headerVerticalPadding ?? memoryNotch.notchConfig.headerPadding ?? 0

                                            Layout.preferredHeight: bodyHeight
                                            Layout.bottomMargin: -bodyHeight

                                            readonly property real shadowExtent: Math.max(...[gpuNotch, memoryNotch, rightNotch].map(n => n.dropShadow.enabled ? n.dropShadow.bottomExtent : 0))
                                            readonly property real windowBottom: {
                                                [gpuNotch.y, gpuNotch.parent?.height, gpuNotch.parentBottomPadding, memoryNotch.y, memoryNotch.height, leftNotchHolder.y, rightNotch.y, rightNotch.height];
                                                return gpuNotch.mapToItem(null, 0, gpuNotch.bodyHeight).y + gpuNotch.shadowExtent;
                                            }
                                            onWindowBottomChanged: root.gpuNotchBottom = windowBottom
                                            Component.onCompleted: root.gpuNotchBottom = windowBottom

                                            transform: Translate {
                                                y: (gpuNotch.parent?.height ?? 0) + gpuNotch.parentBottomPadding - gpuNotch.y
                                            }

                                            headerContent: ColumnLayout {
                                                id: gpuInfoColumn
                                                spacing: ShellConfig.px(20)
                                                Text {
                                                    Layout.alignment: Qt.AlignCenter
                                                    text: "GPU"
                                                    font.pixelSize: ShellConfig.fontPx(20)
                                                    color: Colors.on_surface
                                                    Layout.leftMargin: ShellConfig.px(20)
                                                    Layout.rightMargin: ShellConfig.px(20)
                                                    Layout.topMargin: ShellConfig.px(20)
                                                }
                                                Text {
                                                    Layout.alignment: Qt.AlignCenter
                                                    text: gpuNameProcess.text
                                                    Layout.maximumWidth: ShellConfig.px(330)
                                                    fontSizeMode: Text.HorizontalFit
                                                    minimumPixelSize: 12
                                                    horizontalAlignment: Text.AlignHCenter
                                                    font.pixelSize: ShellConfig.fontPx(20)
                                                    color: Colors.on_surface
                                                    Layout.leftMargin: ShellConfig.px(20)
                                                    Layout.rightMargin: ShellConfig.px(20)
                                                }
                                                Rectangle {
                                                    id: gpuUsagePlaceHolder
                                                    implicitWidth: ShellConfig.px(150)
                                                    implicitHeight: ShellConfig.px(150)
                                                    color: "transparent"
                                                    Layout.alignment: Qt.AlignHCenter
                                                    Visualisers.Usage {
                                                        purpose: "gpu_usage"
                                                        active: root.hovered
                                                        visible: root.hovered
                                                        anchors.fill: parent
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: gpuStatsProcess.usage + "%"
                                                        font.pixelSize: ShellConfig.fontPx(20)
                                                        color: Colors.on_surface
                                                    }
                                                }

                                                TextResourceInformation {
                                                    prefix: "Used"
                                                    reading: gpuStatsProcess.memory > 1024 ? (gpuStatsProcess.memory / 1024).toFixed(1) : gpuStatsProcess.memory
                                                    suffix: gpuStatsProcess.memory > 1024 ? " GB" : " MB"
                                                    tagColor: "transparent"
                                                    horizontalMargin: 20
                                                }

                                                TextResourceInformation {
                                                    prefix: "Freq"
                                                    reading: gpuStatsProcess.freq > 1024 ? (gpuStatsProcess.freq / 1024).toFixed(1) : gpuStatsProcess.freq
                                                    suffix: gpuStatsProcess.freq > 1024 ? " GHz" : " MHz"
                                                    tagColor: "transparent"
                                                    horizontalMargin: 20
                                                    Layout.bottomMargin: ShellConfig.px(30)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                            Text {
                                Layout.topMargin: ShellConfig.px(40)
                                Layout.alignment: Qt.AlignHCenter
                                text: "Temperature"
                                font.pixelSize: ShellConfig.fontPx(24)
                                color: Colors.on_surface
                            }
                            Rectangle {
                                id: cpuTemperaturePlaceHolder
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: ShellConfig.px(146)
                                implicitHeight: ShellConfig.px(146)
                                color: "transparent"

                                Visualisers.Usage {
                                    purpose: "cpu_temp"
                                    active: root.hovered
                                    visible: root.hovered
                                    anchors.fill: parent
                                }

                                Rectangle {
                                    id: gpuTemperaturePlaceHolder
                                    z: -1
                                    anchors.centerIn: parent
                                    width: cpuTemperaturePlaceHolder.width - 2 * ShellConfig.px(13)
                                    height: cpuTemperaturePlaceHolder.height - 2 * ShellConfig.px(13)
                                    color: "transparent"

                                    Visualisers.Usage {
                                        purpose: "gpu_temp"
                                        active: root.hovered
                                        visible: root.hovered
                                        anchors.fill: parent
                                    }
                                }
                            }

                            TextResourceInformation {
                                prefix: "CPU"
                                reading: cpuTempProcess.text
                                tagColor: Colors.primary
                            }

                            TextResourceInformation {
                                prefix: "GPU"
                                reading: gpuStatsProcess.temp
                                tagColor: Qt.hsva((Math.max(Colors.primary.hsvHue, 0) + 0.8 / 8) % 1, Colors.primary.hsvSaturation, Colors.primary.hsvValue, Colors.primary.a)
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: sideBarHoverHandle
                readonly property real activationWidth: ShellConfig.px(shellRoot.configObject?.activationWidth ?? 10)
                readonly property real activationHeight: shellRoot.configObject?.activationHeight !== undefined ? ShellConfig.px(shellRoot.configObject.activationHeight) : root.implicitHeight

                color: (shellRoot.configObject?.showHoverRegion ?? false) ? Qt.rgba(1, 0, 0, 0.35) : 'transparent'
                z: 2
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: activationWidth + (root.hovered ? root.implicitWidth : 0)
                height: root.hovered ? root.implicitHeight : Math.min(activationHeight, root.implicitHeight)

                HoverHandler {
                    blocking: false
                    onHoveredChanged: {
                        root.hovered = hovered;
                    }
                }
            }
        }
    }

    component TextResourceInformation: RowLayout {
        property var prefix: null
        property color tagColor: Colors.tertiary
        property color textColor: Colors.on_surface
        property var reading: 0
        property var horizontalMargin: 20
        property var suffix: "°C"
        Text {
            Layout.alignment: Qt.AlignCenter
            text: prefix
            font.pixelSize: ShellConfig.fontPx(20)
            color: textColor
            Layout.leftMargin: ShellConfig.px(horizontalMargin)
        }
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            implicitWidth: ShellConfig.px(10)
            implicitHeight: ShellConfig.px(10)
            radius: width / 2
            color: tagColor
        }
        Item {
            Layout.fillWidth: true
        }
        Text {
            text: reading + suffix
            font.pixelSize: ShellConfig.fontPx(20)
            color: textColor
            Layout.rightMargin: ShellConfig.px(horizontalMargin)
            Layout.alignment: Qt.AlignCenter
        }
    }
}
