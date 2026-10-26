import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import Quickshell
import Quickshell.Bluetooth

import qs.config
import qs.config.theme
import qs.components.controls

ColumnLayout {
    id: root

    spacing: 0
    Layout.fillHeight: true
    Material.theme: Colors.isDark ? Material.Dark : Material.Light
    Material.accent: Colors.primary
    Material.primary: Colors.primary

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

    property bool shown: true
    property bool startedScan: false
    function stopOwnScan() {
        if (startedScan && adapter)
            adapter.discovering = false;
        startedScan = false;
    }
    onShownChanged: if (!shown)
        stopOwnScan()
    Component.onDestruction: stopOwnScan()
    readonly property bool adapterEnabled: adapter?.enabled ?? false
    readonly property bool adapterBlocked: adapter?.state === BluetoothAdapterState.Blocked
    readonly property bool adapterChanging: adapter?.state === BluetoothAdapterState.Enabling || adapter?.state === BluetoothAdapterState.Disabling

    QtObject {
        id: bluetoothUiState

        property var errors: ({})
        property var pairRequested: ({})

        function setError(address, text) {
            let next = Object.assign({}, errors);
            if (text)
                next[address] = text;
            else
                delete next[address];
            errors = next;
        }

        function setPairRequested(address, requested) {
            let next = Object.assign({}, pairRequested);
            if (requested)
                next[address] = true;
            else
                delete next[address];
            pairRequested = next;
        }
    }

    Pane {
        id: bluetoothCard
        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.alignment: Qt.AlignTop
        Layout.margins: ShellConfig.px(8)
        padding: ShellConfig.px(12)

        background: Rectangle {
            radius: ShellConfig.px(20)
            color: "transparent"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: ShellConfig.px(12)
            Pane {
                Layout.fillWidth: true
                background: Rectangle {
                    radius: ShellConfig.px(30)
                    color: Qt.rgba(Colors.surface_container.r, Colors.surface_container.g, Colors.surface_container.b, .5)
                    border.width: 0.5
                    border.color: Colors.outline
                }
                horizontalPadding: ShellConfig.px(12)
                verticalPadding: ShellConfig.px(4)
                Layout.bottomMargin: ShellConfig.px(18)

                RowLayout {
                    anchors.fill: parent
                    Text {
                        text: "Bluetooth"
                        color: Colors.on_surface
                        font.pixelSize: ShellConfig.fontPx(18)
                        font.bold: true
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        visible: root.adapterEnabled && !root.adapterChanging
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: button.width
                        implicitHeight: button.height
                        color: "transparent"
                        border.width: 1
                        border.color: Colors.primary
                        radius: ShellConfig.px(40)
                        ActionButton {
                            id: button
                            spacing: 0
                            rightInset: 0
                            leftInset: 0
                            topInset: 0
                            bottomInset: 0
                            busy: root.adapter?.discovering ?? false
                            text: busy ? "Stop Scanning" : "Scan"
                            onClicked: {
                                const start = !root.adapter.discovering;
                                root.adapter.discovering = start;
                                root.startedScan = start;
                            }
                        }
                    }

                    BusyIndicator {
                        visible: root.adapterChanging
                        running: visible
                        padding: 0
                        implicitWidth: ShellConfig.px(18)
                        implicitHeight: ShellConfig.px(18)
                    }

                    Switch {
                        id: toggleSwitch
                        scale: ShellConfig.sizeScale
                        Layout.preferredWidth: Math.round(toggleSwitch.implicitWidth * ShellConfig.sizeScale)
                        Layout.preferredHeight: Math.round(toggleSwitch.implicitHeight * ShellConfig.sizeScale)
                        enabled: root.adapter !== null && !root.adapterBlocked && !root.adapterChanging
                        checked: root.adapterEnabled
                        onClicked: {
                            root.adapter.enabled = checked;
                            checked = Qt.binding(() => root.adapterEnabled);
                        }
                    }
                }
            }

            Text {
                font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                visible: text.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: ShellConfig.px(12)
                wrapMode: Text.WordWrap
                color: Colors.on_surface
                opacity: 0.7
                text: {
                    if (root.adapter === null)
                        return "No Bluetooth adapter found.";
                    if (root.adapterBlocked)
                        return "Bluetooth is blocked by a hardware switch or airplane mode.";
                    if (root.adapter.state === BluetoothAdapterState.Enabling)
                        return "Turning on…";
                    if (!root.adapterEnabled)
                        return "Bluetooth is off.";
                    if (devicesColumn.pairedDevices.length + devicesColumn.availableDevices.length === 0)
                        return root.adapter.discovering ? "Looking for devices…" : "No devices found. Try scanning.";
                    return "";
                }
            }

            ColumnLayout {
                id: devicesColumn
                visible: root.adapterEnabled
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
                spacing: ShellConfig.px(20)

                readonly property var allDevices: root.adapter?.devices.values ?? []
                readonly property var pairedDevices: allDevices.filter(dev => dev.paired).sort((a, b) => b.connected - a.connected)
                readonly property var availableDevices: allDevices.filter(dev => !dev.paired && dev.deviceName.length > 0)

                NetworksGroupPane {
                    id: knownNetworksPane
                    isKnown: true
                    uiState: bluetoothUiState
                    networks: devicesColumn.pairedDevices
                    numMinChildren: Math.min(2, knownNetworksPane.networks.length)
                }
                NetworksGroupPane {
                    id: unkownNetworksPane
                    uiState: bluetoothUiState
                    networks: devicesColumn.availableDevices
                    numMinChildren: Math.min(4, unkownNetworksPane.networks.length)
                }
            }
        }
    }
    component NetworksGroupPane: Pane {
        id: bluetoothCard
        property bool isKnown: false

        property var networks: []
        property int numMinChildren: 1
        property QtObject uiState
        Layout.fillHeight: true
        Layout.fillWidth: true
        clip: true
        padding: ShellConfig.px(20)
        visible: networks.length != 0
        background: Rectangle {
            radius: ShellConfig.px(20)
            color: Qt.rgba(Colors.surface_container.r, Colors.surface_container.g, Colors.surface_container.b, .5)
            border.width: 0.5
            border.color: Colors.outline
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: ShellConfig.px(14)

            Text {
                text: bluetoothCard.isKnown ? "Paired Devices" : "Available Devices"
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
            WifiList {
                numMinChildren: bluetoothCard.numMinChildren
                Layout.fillWidth: true
                networks: bluetoothCard.networks
                uiState: bluetoothCard.uiState
            }
        }
    }

    component WifiList: ListView {
        id: bluetoothCard
        property var networks: []
        property int numMinChildren: 1
        property QtObject uiState
        cacheBuffer: 1000
        displayMarginBeginning: ShellConfig.px(-40)

        ScrollBar.vertical: ScrollBar {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: ShellConfig.px(-8)
            policy: ScrollBar.AsNeeded

            contentItem: Rectangle {
                implicitWidth: ShellConfig.px(4)
                radius: ShellConfig.px(20)
                color: Colors.primary
                opacity: 0.5
            }
        }

        highlightMoveDuration: 0

        implicitHeight: (numMinChildren * (contentHeight / (networks.length === 0 ? 1 : networks.length)))

        spacing: ShellConfig.px(8)
        model: ScriptModel {
            values: bluetoothCard.networks
        }
        delegate: Pane {
            id: delegatebluetoothCard
            anchors.left: parent ? parent.left : undefined
            anchors.right: parent ? parent.right : undefined
            horizontalPadding: ShellConfig.px(12)
            verticalPadding: ShellConfig.px(4)

            required property var modelData

            readonly property string errorText: bluetoothCard.uiState.errors[modelData.address] ?? ""
            readonly property bool isChanging: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            property int lastState: modelData.state

            function finishPairing() {
                if (!modelData.paired || !bluetoothCard.uiState.pairRequested[modelData.address])
                    return;
                bluetoothCard.uiState.setPairRequested(modelData.address, false);
                modelData.trusted = true;
                modelData.connect();
            }

            Component.onCompleted: finishPairing()

            Connections {
                target: delegatebluetoothCard.modelData

                function onStateChanged() {
                    let dev = delegatebluetoothCard.modelData;
                    let last = delegatebluetoothCard.lastState;
                    if (last === BluetoothDeviceState.Connecting && dev.state === BluetoothDeviceState.Disconnected)
                        bluetoothCard.uiState.setError(dev.address, "Couldn't connect. Is the device on and in range?");
                    else if (last === BluetoothDeviceState.Disconnecting && dev.state === BluetoothDeviceState.Connected)
                        bluetoothCard.uiState.setError(dev.address, "Couldn't disconnect.");
                    else if (dev.state === BluetoothDeviceState.Connected)
                        bluetoothCard.uiState.setError(dev.address, "");
                    delegatebluetoothCard.lastState = dev.state;
                }

                function onPairedChanged() {
                    delegatebluetoothCard.finishPairing();
                }

                function onPairingChanged() {
                    if (!delegatebluetoothCard.modelData.pairing)
                        pairingCheck.restart();
                }
            }

            Timer {
                id: pairingCheck
                interval: 1000
                onTriggered: {
                    let dev = delegatebluetoothCard.modelData;
                    if (!dev.paired && !dev.pairing && bluetoothCard.uiState.pairRequested[dev.address]) {
                        bluetoothCard.uiState.setPairRequested(dev.address, false);
                        bluetoothCard.uiState.setError(dev.address, "Pairing failed or was cancelled.");
                    }
                }
            }

            Timer {
                running: delegatebluetoothCard.errorText.length > 0
                interval: 6000
                onTriggered: bluetoothCard.uiState.setError(delegatebluetoothCard.modelData.address, "")
            }

            background: Rectangle {
                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, .5)
                radius: ShellConfig.px(40)
                border.width: .5
                border.color: Colors.outline
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: ShellConfig.px(8)

                RowLayout {
                    id: networkInfo
                    Layout.fillWidth: true

                    Text {
                        font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                        text: delegatebluetoothCard.modelData.name
                        color: Colors.on_surface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                        visible: delegatebluetoothCard.modelData.batteryAvailable
                        Layout.alignment: Qt.AlignVCenter
                        text: Math.round(delegatebluetoothCard.modelData.battery * 100) + "%"
                        color: delegatebluetoothCard.modelData.battery >= .8 ? '#00ffb3' : delegatebluetoothCard.modelData.battery >= .5 ? '#d0ff00' : '#ff0000'
                    }

                    ActionButton {
                        id: actionButton
                        verticalPadding: ShellConfig.px(12)
                        horizontalPadding: ShellConfig.px(20)

                        readonly property bool pairing: delegatebluetoothCard.modelData.pairing

                        enabled: pairing || !delegatebluetoothCard.isChanging
                        busy: pairing || delegatebluetoothCard.isChanging
                        busyText: pairing ? (hovered ? "Cancel" : "Pairing…") : delegatebluetoothCard.modelData.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…" : "Connecting…"
                        text: delegatebluetoothCard.modelData.connected ? "Disconnect" : delegatebluetoothCard.modelData.paired ? "Connect" : "Pair"
                        onClicked: {
                            let dev = delegatebluetoothCard.modelData;
                            bluetoothCard.uiState.setError(dev.address, "");
                            if (dev.pairing) {
                                bluetoothCard.uiState.setPairRequested(dev.address, false);
                                dev.cancelPair();
                            } else if (dev.connected) {
                                dev.disconnect();
                            } else if (dev.paired) {
                                dev.connect();
                            } else {
                                bluetoothCard.uiState.setPairRequested(dev.address, true);
                                dev.pair();
                            }
                        }
                    }
                }

                Text {
                    font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                    visible: delegatebluetoothCard.errorText.length > 0
                    text: delegatebluetoothCard.errorText
                    color: Material.color(Material.Red, Material.Shade300)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.bottomMargin: ShellConfig.px(6)
                }
            }
        }
    }
}
