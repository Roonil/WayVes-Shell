import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import qs.config
import qs.components.controls
import qs.config.theme
import qs.components.notch
import qs.enums
import qs.services
import qs.Visualisers

ColumnLayout {
    id: root
    property string activeTab: "Devices"
    property var configObject: undefined
    Pane {
        id: topPane
        Layout.fillWidth: true
        Layout.margins: 0
        padding: ShellConfig.px(20)
        Layout.fillHeight: true
        background: Rectangle {
            color: "transparent"
            radius: ShellConfig.px(20)
        }
        ColumnLayout {
            id: topColumn
            anchors.fill: parent
            spacing: ShellConfig.px(30)

            RowLayout {
                spacing: ShellConfig.px(20)
                Layout.fillWidth: true
                Rectangle {
                    radius: ShellConfig.px(20)
                    Layout.preferredWidth: childrenRect.width + ShellConfig.px(20)
                    Layout.preferredHeight: childrenRect.height + ShellConfig.px(10)
                    color: root.activeTab === "Devices" ? Colors.surface_container : "transparent"
                    border.color: root.activeTab === "Devices" ? Colors.outline : "transparent"
                    Text {
                        text: "Devices"
                        anchors.centerIn: parent
                        color: Colors.on_surface
                        font.pixelSize: ShellConfig.fontPx(24)
                        font.bold: root.activeTab === "Devices"
                        opacity: root.activeTab === "Devices" ? 1.0 : 0.5

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = "Devices";
                            }
                        }
                    }
                }
                Rectangle {
                    radius: ShellConfig.px(20)
                    Layout.preferredWidth: childrenRect.width + ShellConfig.px(20)
                    Layout.preferredHeight: childrenRect.height + ShellConfig.px(10)
                    color: root.activeTab === "Streams" ? Colors.surface_container : "transparent"
                    border.color: root.activeTab === "Streams" ? Colors.outline : "transparent"
                    Text {
                        text: "Streams"
                        color: Colors.on_surface
                        font.pixelSize: ShellConfig.fontPx(24)
                        anchors.centerIn: parent
                        font.bold: root.activeTab === "Streams"
                        opacity: root.activeTab === "Streams" ? 1.0 : 0.5

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = "Streams";
                            }
                        }
                    }
                }
            }

            AudioDevices {
                visible: root.activeTab === "Devices"
                Layout.fillHeight: visible
            }

            AudioStreams {
                visible: root.activeTab === "Streams"
                Layout.fillHeight: visible
            }
        }
    }

    component AudioDevices: ColumnLayout {
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        spacing: ShellConfig.px(24)

        AudioStream {
            audioDirection: 1
            audioType: 1
        }

        AudioStream {
            audioDirection: 0
            audioType: 1
        }
    }

    component AudioStreams: ColumnLayout {
        id: streams
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: ShellConfig.px(24)

        AudioStream {
            audioDirection: 1
            numMinChildren: 3
        }

        AudioStream {
            audioDirection: 0
        }
    }

    component AudioStream: Pane {
        id: streamPane
        property var audioObjects
        property int audioDirection: 0
        property int audioType: 0
        property int nodeId: -1
        property int numMinChildren: 4
        Material.theme: Colors.isDark ? Material.Dark : Material.Light
        Material.accent: Colors.primary
        Material.primary: Colors.primary
        padding: ShellConfig.px(12)
        topPadding: ShellConfig.px(20)
        horizontalPadding: ShellConfig.px(24)
        background: Rectangle {
            color: Qt.rgba(Colors.surface_container.r, Colors.surface_container.g, Colors.surface_container.b, .5)

            radius: ShellConfig.px(20)
            border.color: Colors.outline
            border.width: 0.5
        }
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        contentItem: ColumnLayout {
            id: streams
            spacing: ShellConfig.px(12)

            Text {
                text: (streamPane.audioDirection === 0 ? "Input " : "Output ") + (streamPane.audioType === 0 ? "Streams" : "Devices")
                font.pixelSize: ShellConfig.fontPx(20)
                font.bold: true

                color: Colors.on_surface
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: ShellConfig.px(-8)
            }

            ToolSeparator {
                id: separator
                orientation: Qt.Horizontal
                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                Layout.leftMargin: ShellConfig.px(-4)
                contentItem: Rectangle {
                    implicitWidth: separator.vertical ? 1 : ShellConfig.px(20)
                    implicitHeight: separator.vertical ? ShellConfig.px(20) : 1
                    color: Colors.outline
                    opacity: 0.5
                }
            }

            Text {
                text: "No " + (streamPane.audioType === 0 ? "Streams" : "Devices") + " detected!"
                font.pixelSize: ShellConfig.fontPx(20)
                visible: streamsRepeater.model.length == 0
                color: Colors.on_surface
                Layout.bottomMargin: ShellConfig.px(8)
                Layout.alignment: Qt.AlignTop
            }

            ListView {
                id: streamsRepeater
                spacing: ShellConfig.px(20)

                property int numMinChildren: streamPane.numMinChildren
                Layout.fillWidth: true
                displayMarginBeginning: ShellConfig.px(-44)
                displayMarginEnd: ShellConfig.px(-40)
                implicitHeight: ((Math.min(numMinChildren, model.length) - .02) * ((contentHeight) / Math.max(1, model.length)))
                visible: model.length > 0
                cacheBuffer: 100

                ScrollBar.vertical: ScrollBar {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: ShellConfig.px(-20)
                    policy: ScrollBar.AsNeeded

                    contentItem: Rectangle {
                        implicitWidth: ShellConfig.px(4)
                        radius: ShellConfig.px(20)
                        color: Colors.primary
                        opacity: 0.5
                    }
                }

                highlightMoveDuration: 0
                model: streamPane.audioType === 1 ? streamPane.audioDirection === 1 ? PWTrackedObjects.hardwareOutputs : PWTrackedObjects.hardwareInputs : streamPane.audioDirection === 1 ? PWTrackedObjects.outputStreams : PWTrackedObjects.inputStreams.filter(node => node.properties["application.name"] != "WayVes_audio_overview" && node.properties["application.name"] != undefined)

                delegate: ColumnLayout {
                    id: delegateRoot
                    readonly property var listView: ListView.view
                    spacing: ShellConfig.px(4)
                    width: listView?.width ?? 0
                    z: streamsRepeater.count - index

                    readonly property var activeApplication: modelData

                    Text {
                        Layout.fillWidth: true

                        font.pixelSize: ShellConfig.fontPx(18)
                        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                        text: (streamPane.audioType === 0 ? streamPane.audioDirection === 0 ? modelData?.properties["application.name"] : modelData?.name : modelData?.description) ?? "No Device"
                        color: Colors.on_surface
                    }
                    RowLayout {
                        id: row
                        Layout.fillWidth: true
                        spacing: ShellConfig.px(4)
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop

                        Rectangle {
                            z: 2

                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                            Layout.preferredHeight: streamSoundControls.implicitHeight
                            color: "transparent"

                            SoundControls {
                                id: streamSoundControls
                                audioType: streamPane.audioType
                                audioDirection: streamPane.audioDirection
                                activeApplication: delegateRoot.activeApplication
                                anchors.fill: parent
                                notchXTranslate: (streamPane.leftPadding ?? streamPane.horizontalPadding ?? streamPane.padding ?? 0) + (topPane.leftPadding ?? topPane.horizontalPadding ?? topPane.padding ?? 0)
                                nodeId: streamPane.audioType === 0 ? modelData?.properties["object.serial"] ?? 0 : modelData?.id
                                audioObject: modelData.audio
                                listView: delegateRoot.listView
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    component SoundControls: RowLayout {
        id: soundControlsRoot
        property var audioObject
        property int audioType: 0
        property int audioDirection: 0
        property var linkTracker: undefined
        property var activeApplication: undefined
        property var listView: undefined
        property int nodeId: 0

        property int notchXTranslate: 0

        Layout.fillWidth: true
        spacing: ShellConfig.px(4)

        Item {
            z: 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight | Qt.AlignTop

            Item {
                anchors.left: parent.left
                anchors.top: parent.top

                transform: Translate {
                    x: -soundControlsRoot.notchXTranslate
                    y: ShellConfig.px(-32)
                }

                Notch {
                    id: sideNotch
                    z: 2
                    configObject: root.configObject
                    anchors.right: parent.right
                    checkParentBottomLeftOverflow: true

                    direction: Directions.Left

                    onExpandedChanged: {
                        if (expanded) {
                            Quickshell.execDetached(["sh", "-c", `WayVes audio -a WayVes_audio_overview -t  ${soundControlsRoot.activeApplication?.properties["object.serial"]?.toString()}`]);
                        }
                    }

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
                        spacing: 0

                        Item {
                            z: 2

                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            transform: Translate {
                                y: -(sideNotch.notchConfig.contentTopPadding ?? sideNotch.notchConfig.contentVerticalPadding ?? sideNotch.notchConfig.contentPadding ?? 0)
                            }

                            Rectangle {
                                height: ShellConfig.px(120)
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.top
                                color: "transparent"
                                Visualisers.AudioOverview {
                                    readonly property real panelOpacity: sideNotch.panelOpacity

                                    function pushPanelOpacity() {
                                        if (ready)
                                            Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'panelOpacity=${panelOpacity}' > /tmp/WayVes/audio_tracker`]);
                                    }

                                    active: sideNotch.expanded
                                    visible: sideNotch.expanded
                                    anchors.fill: parent
                                    onReadyChanged: pushPanelOpacity()
                                    onPanelOpacityChanged: pushPanelOpacity()
                                }
                            }
                        }
                        ColumnLayout {
                            visible: streamPane.audioType === 1

                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            spacing: ShellConfig.px(6)

                            Rectangle {
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                implicitWidth: childrenRect.width
                                implicitHeight: childrenRect.height
                                color: Colors.primary_container
                                border.width: 1
                                border.color: Colors.primary
                                radius: ShellConfig.px(40)
                                ScaledRoundButton {
                                    spacing: 0
                                    rightInset: 0
                                    leftInset: 0
                                    topInset: 0
                                    bottomInset: 0
                                    flat: true

                                    Component {
                                        id: nodeTrackerComponent
                                        Item {
                                            property var pwNode: null

                                            PwNodeLinkTracker {
                                                id: linkTracker
                                                node: pwNode
                                            }

                                            function getLinks() {
                                                return linkTracker.linkGroups;
                                            }
                                        }
                                    }
                                    text: streamPane.audioDirection == 1 ? "Play all audio using this device" : "Record all audio using this device"
                                    onClicked: {
                                        var streams = streamPane.audioDirection == 1 ? PWTrackedObjects.hardwareOutputs : PWTrackedObjects.hardwareInputs;

                                        for (let stream of streams) {
                                            if (stream.id === nodeId)
                                                continue;

                                            var nodeObj = nodeTrackerComponent.createObject(root, {
                                                "pwNode": stream
                                            });

                                            for (var group of nodeObj.getLinks()) {
                                                Quickshell.execDetached(["pw-link", "-d", group.source.id.toString(), group.target.id.toString()]);
                                                Quickshell.execDetached(["pw-link", group.source.id, nodeId.toString()]);
                                            }
                                            nodeObj.destroy();
                                        }
                                    }
                                    HoverHandler {
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                        Pane {

                            visible: soundControlsRoot.audioType === 0
                            Layout.fillHeight: true
                            Layout.preferredWidth: childrenRect.width
                            padding: ShellConfig.px(12)
                            topPadding: ShellConfig.px(20)
                            horizontalPadding: ShellConfig.px(24)

                            background: Rectangle {
                                color: Qt.rgba(Colors.surface_container.r, Colors.surface_container.g, Colors.surface_container.b, .5)

                                radius: ShellConfig.px(20)
                                border.color: Colors.outline
                                border.width: 0.5
                            }
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: ShellConfig.px(2)
                                Item {
                                    Layout.fillHeight: true
                                }
                                Text {
                                    text: soundControlsRoot.audioDirection === 0 ? "Record audio using:" : "Play audio using:"
                                    color: Colors.on_surface
                                    font.pixelSize: ShellConfig.fontPx(18)
                                    font.bold: true

                                    Layout.bottomMargin: ShellConfig.px(8)
                                }
                                ToolSeparator {
                                    id: separator
                                    orientation: Qt.Horizontal
                                    Layout.alignment: Qt.AlignLeft
                                    Layout.fillWidth: true
                                    Layout.leftMargin: ShellConfig.px(-4)
                                    contentItem: Rectangle {
                                        implicitWidth: separator.vertical ? 1 : ShellConfig.px(20)
                                        implicitHeight: separator.vertical ? ShellConfig.px(20) : 1
                                        color: Colors.outline
                                        opacity: 0.5
                                    }
                                }
                                Repeater {
                                    model: soundControlsRoot.audioDirection === 0 ? PWTrackedObjects.hardwareInputs : PWTrackedObjects.hardwareOutputs
                                    delegate: Pane {
                                        id: devicesPane

                                        padding: 0
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignCenter

                                        readonly property var activeLink: {
                                            for (let group of Pipewire.linkGroups.values) {
                                                var currentNode = soundControlsRoot.audioDirection === 0 ? group?.target : group?.source;
                                                if ((currentNode.id) === soundControlsRoot.activeApplication?.id && (soundControlsRoot.audioDirection === 1 ? !group.target.isStream : true)) {
                                                    return group;
                                                }
                                            }
                                        }

                                        background: Rectangle {
                                            color: "transparent"

                                            z: 0
                                            radius: ShellConfig.px(20)
                                        }
                                        RadioButton {
                                            padding: ShellConfig.px(8)
                                            verticalPadding: ShellConfig.px(14)
                                            font.pixelSize: ShellConfig.fontPx(14)
                                            id: radioButton
                                            Binding {
                                                target: radioButton.indicator
                                                property: "scale"
                                                value: ShellConfig.sizeScale
                                            }
                                            contentItem: Text {
                                                text: radioButton.text
                                                font: radioButton.font
                                                color: Colors.on_surface

                                                leftPadding: radioButton.indicator.width + radioButton.spacing
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            HoverHandler {
                                                cursorShape: Qt.PointingHandCursor
                                            }
                                            text: modelData?.description

                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignCenter
                                            checked: (soundControlsRoot.audioDirection === 0 ? devicesPane.activeLink?.source : devicesPane.activeLink?.target)?.description === modelData?.description

                                            onClicked: {
                                                if (streamPane.audioDirection === 0) {
                                                    Quickshell.execDetached(["pw-link", "-d", devicesPane.activeLink?.source?.id.toString(), soundControlsRoot.activeApplication?.id.toString()]);
                                                    Quickshell.execDetached(["pw-link", modelData?.id.toString(), soundControlsRoot.activeApplication?.id.toString()]);
                                                    return;
                                                }
                                                Quickshell.execDetached(["pw-link", "-d", soundControlsRoot.activeApplication?.id.toString(), devicesPane.activeLink?.target?.id.toString()]);
                                                Quickshell.execDetached(["pw-link", soundControlsRoot.activeApplication?.id.toString(), modelData?.id.toString()]);
                                            }
                                        }
                                    }
                                }
                                Item {
                                    Layout.fillHeight: true
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: iconHolder
            Layout.preferredWidth: childrenRect.width + ShellConfig.px(10)
            Layout.preferredHeight: childrenRect.height + ShellConfig.px(10)
            color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, .5)
            border.width: .5
            border.color: Colors.outline
            radius: ShellConfig.px(20)
            IconImage {
                id: icon
                anchors.centerIn: parent
                width: ShellConfig.px(12)
                height: ShellConfig.px(12)

                mipmap: true

                backer.sourceSize.width: 25
                backer.sourceSize.height: 25
                visible: source != ""
                source: {
                    const icon = "audio-volume-" + (audioObject.muted || audioObject.volume === 0 ? "muted" : "high" + "-symbolic");
                    return Quickshell.iconPath(icon);
                    return `image://icon/${icon}`;
                }

                ColorOverlay {
                    anchors.fill: icon
                    source: icon
                    color: Colors.on_surface
                }
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {

                    onTapped: {
                        audioObject.muted = !audioObject.muted;
                    }
                }
            }
        }
        Slider {
            id: volumeSlider
            padding: ShellConfig.px(6)

            Binding {
                target: volumeSlider.handle
                property: "scale"
                value: ShellConfig.sizeScale
            }

            background: Item {
                x: volumeSlider.leftPadding
                y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2
                implicitWidth: ShellConfig.px(200)
                implicitHeight: ShellConfig.px(48)
                width: volumeSlider.availableWidth
                height: ShellConfig.px(4)

                Rectangle {
                    x: volumeSlider.implicitHandleWidth / 2
                    width: parent.width - volumeSlider.implicitHandleWidth
                    height: parent.height
                    radius: height / 2
                    color: volumeSlider.enabled ? Qt.alpha(volumeSlider.Material.accentColor, 0.33) : volumeSlider.Material.sliderDisabledColor

                    Rectangle {
                        width: volumeSlider.position * parent.width
                        height: parent.height
                        radius: height / 2
                        color: volumeSlider.enabled ? volumeSlider.Material.accentColor : volumeSlider.Material.sliderDisabledColor
                    }
                }
            }

            Layout.fillWidth: true
            from: 0
            to: 1
            value: audioObject.volume ?? 0
            onMoved: {
                if (audioObject) {
                    audioObject.volume = value;
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
    Item {
        Layout.fillHeight: true
    }
}
