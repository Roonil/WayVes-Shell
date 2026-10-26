import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import Quickshell
import Quickshell.Networking

import qs.config
import qs.config.theme
import qs.components.controls

Pane {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    Material.theme: Colors.isDark ? Material.Dark : Material.Light
    Material.accent: Colors.primary
    Material.primary: Colors.primary

    Layout.alignment: Qt.AlignTop
    Layout.margins: ShellConfig.px(8)
    readonly property var wifiNetworkCard: Networking.devices.values.filter(device => device.type === DeviceType.Wifi)
    readonly property var wifiDevice: wifiNetworkCard.length > 0 ? wifiNetworkCard[0] : null

    property bool shown: true
    property bool startedScan: false
    function stopOwnScan() {
        if (startedScan && wifiDevice)
            wifiDevice.scannerEnabled = false;
        startedScan = false;
    }
    onShownChanged: if (!shown)
        stopOwnScan()
    Component.onDestruction: stopOwnScan()
    padding: ShellConfig.px(12)

    QtObject {
        id: wifiUiState

        property string promptingNetwork: ""
        property var errors: ({})
        property var freshProfiles: ({})

        function setError(name, text) {
            let next = Object.assign({}, errors);
            if (text)
                next[name] = text;
            else
                delete next[name];
            errors = next;
        }

        function setFresh(name, fresh) {
            let next = Object.assign({}, freshProfiles);
            if (fresh)
                next[name] = true;
            else
                delete next[name];
            freshProfiles = next;
        }
    }

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
                    text: "Wi-Fi"
                    color: Colors.on_surface
                    font.pixelSize: ShellConfig.fontPx(18)
                    font.bold: true
                }
                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: Networking.wifiEnabled && root.wifiDevice !== null

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
                        busy: root.wifiDevice?.scannerEnabled ?? false
                        text: busy ? "Stop Scanning" : "Scan"
                        onClicked: {
                            root.wifiDevice.scannerEnabled = !root.wifiDevice.scannerEnabled;
                            root.startedScan = root.wifiDevice.scannerEnabled;
                        }
                    }
                }

                Switch {
                    id: toggleSwitch
                    scale: ShellConfig.sizeScale
                    Layout.preferredWidth: Math.round(toggleSwitch.implicitWidth * ShellConfig.sizeScale)
                    Layout.preferredHeight: Math.round(toggleSwitch.implicitHeight * ShellConfig.sizeScale)
                    enabled: Networking.wifiHardwareEnabled
                    checked: Networking.wifiEnabled
                    onClicked: {
                        Networking.wifiEnabled = checked;
                        checked = Qt.binding(() => Networking.wifiEnabled);
                    }
                }
            }
        }

        Text {
            font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
            readonly property int networkCount: root.wifiDevice?.networks?.values.length ?? 0

            visible: text.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: ShellConfig.px(12)
            wrapMode: Text.WordWrap
            color: Colors.on_surface
            opacity: 0.7
            text: {
                if (root.wifiDevice === null)
                    return "No Wi-Fi adapter found.";
                if (!Networking.wifiHardwareEnabled)
                    return "Wi-Fi is blocked by a hardware switch or airplane mode.";
                if (!Networking.wifiEnabled)
                    return "Wi-Fi is off.";
                if (networkCount === 0)
                    return root.wifiDevice.scannerEnabled ? "Looking for networks…" : "No networks found. Try scanning.";
                return "";
            }
        }

        Repeater {
            id: hardwareDevice
            model: root.wifiNetworkCard

            ColumnLayout {
                visible: Networking.wifiEnabled
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
                spacing: ShellConfig.px(20)

                NetworksGroupPane {
                    id: knownNetworksPane
                    isKnown: true
                    uiState: wifiUiState
                    networks: !modelData.networks ? [] : modelData.networks.values.filter(net => net.known).sort((a, b) => b.signalStrength - a.signalStrength).sort((a, b) => b.connected - a.connected)
                    numMinChildren: Math.min(2, knownNetworksPane.networks.length)
                }
                NetworksGroupPane {
                    id: unkownNetworksPane
                    uiState: wifiUiState
                    networks: !modelData.networks ? [] : modelData.networks.values.filter(net => !net.known).sort((a, b) => b.signalStrength - a.signalStrength)
                    numMinChildren: Math.min(4, unkownNetworksPane.networks.length)
                }
            }
        }
    }
    component NetworksGroupPane: Pane {
        id: root
        property var networks: []
        property bool isKnown: false
        property int numMinChildren: 1
        property QtObject uiState
        Layout.fillHeight: true
        Layout.fillWidth: true
        padding: ShellConfig.px(20)
        clip: true
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
                text: (root.isKnown ? "Known " : "Unknown ") + "Networks"
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
                numMinChildren: root.numMinChildren
                Layout.fillWidth: true
                networks: root.networks
                uiState: root.uiState
            }
        }
    }

    component WifiList: ListView {
        id: root
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

        implicitHeight: (numMinChildren * (contentHeight / (networks.length == 0 ? 1 : networks.length)))

        spacing: ShellConfig.px(8)
        model: ScriptModel {
            values: root.networks
        }
        delegate: Pane {
            id: delegateRoot
            anchors.left: parent ? parent.left : undefined
            anchors.right: parent ? parent.right : undefined
            horizontalPadding: ShellConfig.px(12)
            verticalPadding: ShellConfig.px(4)

            required property var modelData

            readonly property bool isPrompting: root.uiState.promptingNetwork === modelData.name && !modelData.connected
            readonly property string errorText: root.uiState.errors[modelData.name] ?? ""

            readonly property bool isOpen: modelData.security === WifiSecurityType.Open || modelData.security === WifiSecurityType.Owe
            readonly property bool usesPsk: modelData.security === WifiSecurityType.WpaPsk || modelData.security === WifiSecurityType.Wpa2Psk || modelData.security === WifiSecurityType.Sae

            function startConnect() {
                root.uiState.setError(modelData.name, "");
                if (modelData.known || isOpen) {
                    modelData.connect();
                } else if (usesPsk) {
                    root.uiState.promptingNetwork = isPrompting ? "" : modelData.name;
                } else {
                    root.uiState.setError(modelData.name, "This network type (" + WifiSecurityType.toString(modelData.security) + ") isn't supported here.");
                }
            }

            function submitPassword() {
                if (!passwordInput.acceptableInput)
                    return;
                if (!modelData.known)
                    root.uiState.setFresh(modelData.name, true);
                root.uiState.setError(modelData.name, "");
                modelData.connectWithPsk(passwordInput.text);
                root.uiState.promptingNetwork = "";
                passwordInput.text = "";
            }

            Connections {
                target: delegateRoot.modelData

                function onConnectionFailed(reason) {
                    let name = delegateRoot.modelData.name;
                    let fresh = root.uiState.freshProfiles[name] === true;
                    let message;
                    switch (reason) {
                    case ConnectionFailReason.NoSecrets:
                        message = fresh ? "Wrong password." : "A password is needed.";
                        break;
                    case ConnectionFailReason.WifiAuthTimeout:
                        message = "Authentication timed out. Wrong password?";
                        break;
                    case ConnectionFailReason.WifiNetworkLost:
                        message = "The network went out of range.";
                        break;
                    default:
                        message = "Couldn't connect.";
                    }
                    root.uiState.setError(name, message);

                    if (fresh) {
                        root.uiState.setFresh(name, false);
                        delegateRoot.modelData.forget();
                    }
                    if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout)
                        root.uiState.promptingNetwork = name;
                }

                function onConnectedChanged() {
                    if (delegateRoot.modelData.connected) {
                        root.uiState.setFresh(delegateRoot.modelData.name, false);
                        root.uiState.setError(delegateRoot.modelData.name, "");
                    }
                }
            }

            Timer {
                running: delegateRoot.errorText.length > 0 && !delegateRoot.isPrompting
                interval: 6000
                onTriggered: root.uiState.setError(delegateRoot.modelData.name, "")
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
                        text: delegateRoot.modelData.name
                        color: Colors.on_surface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        radius: ShellConfig.px(40)
                        width: ShellConfig.px(10)
                        height: ShellConfig.px(10)
                        color: delegateRoot.modelData.signalStrength >= .8 ? '#00ffb3' : delegateRoot.modelData.signalStrength >= .5 ? '#d0ff00' : '#ff0000'
                    }

                    ActionButton {
                        verticalPadding: ShellConfig.px(12)
                        horizontalPadding: ShellConfig.px(20)

                        enabled: !delegateRoot.modelData.stateChanging
                        busy: delegateRoot.modelData.stateChanging
                        busyText: delegateRoot.modelData.state === ConnectionState.Disconnecting ? "Disconnecting…" : "Connecting…"
                        text: delegateRoot.modelData.connected ? "Disconnect" : delegateRoot.isPrompting ? "Cancel" : "Connect"
                        onClicked: {
                            if (delegateRoot.modelData.connected)
                                delegateRoot.modelData.disconnect();
                            else
                                delegateRoot.startConnect();
                        }
                    }
                }

                Text {
                    font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                    visible: delegateRoot.errorText.length > 0
                    text: delegateRoot.errorText
                    color: Material.color(Material.Red, Material.Shade300)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.bottomMargin: delegateRoot.isPrompting ? 0 : ShellConfig.px(6)
                }

                RowLayout {
                    visible: delegateRoot.isPrompting
                    Layout.fillWidth: true
                    Layout.bottomMargin: ShellConfig.px(4)
                    spacing: ShellConfig.px(8)

                    TextField {
                        font.pixelSize: ShellConfig.fontPx(16)
                        id: passwordInput
                        placeholderText: "Password"
                        echoMode: TextField.Password
                        Layout.fillWidth: true
                        color: Colors.on_surface

                        validator: RegularExpressionValidator {
                            regularExpression: /^(.{8,63}|[0-9A-Fa-f]{64})$/
                        }

                        topPadding: ShellConfig.px(16)
                        bottomPadding: ShellConfig.px(8)

                        onVisibleChanged: {
                            if (visible)
                                forceActiveFocus();
                            else
                                text = "";
                        }
                        onAccepted: delegateRoot.submitPassword()
                        Keys.onEscapePressed: root.uiState.promptingNetwork = ""

                        background: Rectangle {
                            color: Qt.rgba(Colors.surface_container.r, Colors.surface_container.g, Colors.surface_container.b, .5)
                            radius: ShellConfig.px(10)
                            border.width: passwordInput.activeFocus ? 2 : 1
                            border.color: passwordInput.activeFocus ? Colors.primary : Colors.outline

                            Rectangle {
                                id: labelBg
                                visible: passwordInput.activeFocus || passwordInput.text.length > 0
                                x: ShellConfig.px(10)
                                y: ShellConfig.px(-7)
                                width: ShellConfig.px(70)
                                height: ShellConfig.px(14)
                                color: Colors.surface
                            }
                        }
                    }

                    Button {
                        font.pixelSize: ShellConfig.fontPx(14)
                        text: "Go"
                        enabled: passwordInput.acceptableInput
                        onClicked: delegateRoot.submitPassword()
                    }
                }

                Text {
                    visible: delegateRoot.isPrompting && passwordInput.text.length > 0 && !passwordInput.acceptableInput
                    text: "Passwords are 8 to 63 characters."
                    color: Colors.on_surface
                    opacity: 0.7
                    font.pixelSize: ShellConfig.fontPx(12)
                    Layout.leftMargin: ShellConfig.px(4)
                    Layout.bottomMargin: ShellConfig.px(6)
                }
            }
        }
    }
}
