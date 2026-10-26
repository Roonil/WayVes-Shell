import QtQuick
import QtQuick.Controls.Material
import QtQuick.Effects
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pam
import Quickshell.Widgets

import qs.config
import qs.components.notch
import qs.config.theme
import qs.enums
import qs.services
import qs.Visualisers

Scope {
    id: lock
    signal changeLockState(bool locked)
    property var configObject: undefined
    property bool locked: true

    property bool fake: false

    WlSessionLock {
        locked: !lock.fake && lock.locked

        surface: WlSessionLockSurface {
            Loader {
                anchors.fill: parent
                sourceComponent: lockContent
            }
        }
    }

    PanelWindow {
        visible: lock.fake && lock.locked
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "lockscreen-preview"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Loader {
            anchors.fill: parent
            active: lock.fake
            sourceComponent: lockContent
        }
    }

    Component {
        id: lockContent

        Rectangle {
            id: lockSurface
            width: Quickshell.screens[0].width
            height: Quickshell.screens[0].height
            readonly property color themeTint: Colors.primary
            color: Qt.tint('#050714', Qt.rgba(themeTint.r, themeTint.g, themeTint.b, 0.04))
            readonly property color notchColor: {
                let c = Qt.tint('#14141c', Qt.rgba(themeTint.r, themeTint.g, themeTint.b, 0.08));
                return Qt.rgba(c.r, c.g, c.b, 0.85);
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            readonly property date lockedAt: new Date()

            readonly property int hour: clock.date.getHours()
            readonly property bool stillUp: hour < 5
            readonly property string greeting: hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"

            readonly property string userName: GetUserName.userFullName || Quickshell.env("USER") || ""

            Rectangle {
                width: parent.width
                height: ShellConfig.px(660)

                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"

                Visualisers.LockScreenBackground {
                    id: lockScreenBackground
                    anchors.fill: parent
                    active: true
                    visible: true
                }
            }
            Rectangle {
                width: parent.width
                height: ShellConfig.px(300)
                color: "transparent"
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.alignment: Qt.AlignHCenter

                    Notch {
                        anchors.horizontalCenter: parent.horizontalCenter
                        panelColor: lockSurface.notchColor
                        headerContent: Item {
                            implicitWidth: Math.max(ShellConfig.px(600), greetingColumn.implicitWidth + ShellConfig.px(80))
                            implicitHeight: greetingColumn.implicitHeight + ShellConfig.px(28)

                            ColumnLayout {
                                id: greetingColumn
                                anchors.centerIn: parent
                                spacing: 0

                                Item {
                                    readonly property real maxWidth: ShellConfig.px(900)
                                    readonly property real fit: Math.min(1, maxWidth / Math.max(greetingRow.implicitWidth, 1))

                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: greetingRow.implicitWidth * fit
                                    implicitHeight: greetingRow.implicitHeight * fit

                                    Row {
                                        id: greetingRow
                                        anchors.centerIn: parent
                                        scale: parent.fit

                                        Text {
                                            text: lockSurface.stillUp ? "Still up" : lockSurface.greeting
                                            color: "white"
                                            opacity: 0.85
                                            font.family: "LT Beverage"
                                            font.pixelSize: ShellConfig.fontPx(62)
                                        }
                                        Text {
                                            visible: lockSurface.userName.length > 0
                                            text: ","
                                            color: "white"
                                            opacity: 0.85
                                            font.family: "LT Beverage"
                                            font.pixelSize: ShellConfig.fontPx(62)
                                        }
                                        Text {
                                            visible: lockSurface.userName.length > 0
                                            text: " " + lockSurface.userName
                                            color: "white"
                                            opacity: 0.85
                                            font.family: "LT Beverage"
                                            font.pixelSize: ShellConfig.fontPx(62)
                                        }
                                        Text {
                                            visible: lockSurface.stillUp
                                            text: "?"
                                            color: "white"
                                            opacity: 0.85
                                            font.family: "LT Beverage"
                                            font.pixelSize: ShellConfig.fontPx(62)
                                        }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: ShellConfig.px(6)
                                    text: "Locked since " + Qt.formatDateTime(lockSurface.lockedAt, "HH:mm")
                                    color: "#a6adc8"
                                    font.pixelSize: ShellConfig.fontPx(18)
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"

                        ColumnLayout {
                            anchors.centerIn: parent
                            transform: Translate {
                                y: ShellConfig.px(-340)
                            }
                            Text {
                                text: Qt.formatDateTime(clock.date, "HH:mm")
                                color: "white"
                                font {
                                    family: "LT Beverage"
                                }
                                font.pixelSize: ShellConfig.fontPx(170)
                                Layout.alignment: Qt.AlignHCenter
                                font.weight: Font.Thin
                            }
                            Text {
                                text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                                color: "#a6adc8"
                                Layout.alignment: Qt.AlignHCenter
                                font {
                                    family: "LT Beverage"
                                }
                                font.pixelSize: ShellConfig.fontPx(58)
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }
                }

                Rectangle {
                    height: ShellConfig.px(50)
                    Layout.fillWidth: true
                    color: "transparent"
                }
            }

            readonly property var player: {
                let players = Mpris.players.values;
                return players.find(p => p.playbackState === MprisPlaybackState.Playing) ?? players.find(p => p.playbackState === MprisPlaybackState.Paused) ?? null;
            }
            readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing

            property bool capsLock: false

            Process {
                id: capsLockReader
                command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null"]
                stdout: StdioCollector {
                    onStreamFinished: lockSurface.capsLock = text.split("\n").some(value => value.trim().length > 0 && value.trim() !== "0")
                }
            }

            Timer {
                interval: 500
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    if (!capsLockReader.running)
                        capsLockReader.running = true;
                }
            }

            Item {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                Notch {
                    id: loginNotch
                    configObject: lock.configObject?.notch
                    panelColor: lockSurface.notchColor
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter

                    direction: Directions.Up

                    headerContent: Item {
                        implicitWidth: ShellConfig.px(600)
                        implicitHeight: loginColumn.implicitHeight

                        ColumnLayout {
                            id: loginColumn
                            anchors.centerIn: parent
                            width: parent.width - ShellConfig.px(56)
                            spacing: ShellConfig.px(18)

                            Item {
                                visible: lockSurface.player !== null
                                Layout.fillWidth: true
                                implicitHeight: mediaRow.implicitHeight + (lockSurface.playing ? ShellConfig.px(112) : 0)

                                Visualisers.BottomWaves {
                                    id: lockWaves
                                    anchors.fill: parent
                                    anchors.topMargin: -(loginNotch.notchConfig.headerTopPadding ?? 0)
                                    anchors.leftMargin: -loginColumn.x
                                    anchors.rightMargin: -loginColumn.x
                                    active: lockSurface.playing
                                    visible: active

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: lockWavesMask
                                        brightness: Colors.isDark ? 0 : 0.45
                                    }
                                }

                                Rectangle {
                                    id: lockWavesMask
                                    anchors.fill: lockWaves
                                    visible: false
                                    layer.enabled: true
                                    color: "black"
                                    topLeftRadius: Math.max(loginNotch.topLeftRadius, 0)
                                    topRightRadius: Math.max(loginNotch.topRightRadius, 0)
                                }

                                RowLayout {
                                    id: mediaRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    spacing: ShellConfig.px(18)

                                    ClippingRectangle {
                                        implicitWidth: ShellConfig.px(88)
                                        implicitHeight: ShellConfig.px(88)
                                        radius: ShellConfig.px(16)
                                        color: '#181818'

                                        Image {
                                            anchors.fill: parent
                                            source: lockSurface.player?.trackArtUrl ?? ""
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize.width: 176
                                            sourceSize.height: 176
                                            asynchronous: true
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: ShellConfig.px(4)

                                        Text {
                                            Layout.fillWidth: true
                                            text: lockSurface.player?.trackTitle || "Unknown title"
                                            color: "white"
                                            font.pixelSize: ShellConfig.fontPx(26)
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: lockSurface.player?.trackArtist || lockSurface.player?.identity || ""
                                            color: "#a6adc8"
                                            font.pixelSize: ShellConfig.fontPx(19)
                                            elide: Text.ElideRight
                                        }
                                    }

                                    RowLayout {
                                        spacing: 0
                                        Material.foreground: "white"

                                        RoundButton {
                                            text: "󰒮"
                                            font.pointSize: 24 * ShellConfig.fontScale
                                            background: Item {}
                                            focusPolicy: Qt.NoFocus
                                            enabled: lockSurface.player?.canGoPrevious ?? false
                                            onClicked: lockSurface.player.previous()
                                            HoverHandler {
                                                cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            }
                                        }
                                        RoundButton {
                                            text: lockSurface.player?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                            font.pointSize: 24 * ShellConfig.fontScale
                                            background: Item {}
                                            focusPolicy: Qt.NoFocus
                                            enabled: lockSurface.player?.canTogglePlaying ?? false
                                            onClicked: lockSurface.player.togglePlaying()
                                            HoverHandler {
                                                cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            }
                                        }
                                        RoundButton {
                                            text: "󰒭"
                                            font.pointSize: 24 * ShellConfig.fontScale
                                            background: Item {}
                                            focusPolicy: Qt.NoFocus
                                            enabled: lockSurface.player?.canGoNext ?? false
                                            onClicked: lockSurface.player.next()
                                            HoverHandler {
                                                cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: ShellConfig.px(12)

                                Item {
                                    Layout.fillWidth: true
                                    implicitHeight: ShellConfig.px(56)

                                    id: passwordBox

                                    Component.onCompleted: {
                                        if (!pamAuth.active) {
                                            pamAuth.start();
                                        }
                                        sendMask();
                                    }
                                    Component.onDestruction: Quickshell.execDetached(["timeout", "1", "sh", "-c", `printf '%s\\n' "$1" > ${maskPipe}`, "sh", "pwLength=0\npwEdits=0"])

                                    readonly property string maskPipe: "/tmp/WayVes/linear_password_mask"
                                    readonly property bool maskAvailable: passwordMask.ready
                                    readonly property int maskLength: [...passwordField.text].length
                                    property int maskEdits: 0

                                    onMaskEditsChanged: Qt.callLater(sendMask)

                                    function sendMask() {
                                        maskWriter.send(`pwLength=${maskLength}\npwEdits=${maskEdits}`);
                                    }


                                    Process {
                                        id: maskWriter
                                        property string latest: ""
                                        property bool dirty: false

                                        function send(message) {
                                            latest = message;
                                            if (running) {
                                                dirty = true;
                                            } else {
                                                write();
                                            }
                                        }
                                        function write() {
                                            dirty = false;
                                            command = ["timeout", "1", "sh", "-c", `printf '%s\\n' "$1" > ${passwordBox.maskPipe}`, "sh", latest];
                                            running = true;
                                        }
                                        onExited: if (dirty)
                                            write()
                                    }
                                    PamContext {
                                        id: pamAuth
                                        config: "login"

                                        property string pendingPassword: ""

                                        onResponseRequiredChanged: {
                                            if (responseRequired && pendingPassword.length > 0) {
                                                respond(pendingPassword);
                                                pendingPassword = "";
                                            }
                                        }

                                        onCompleted: result => {
                                            if (result === PamResult.Success) {
                                                lockScreenBackground.active = false;
                                                lockScreenBackground.visible = false;
                                                lock.locked = false;

                                                lock.changeLockState(lock.locked);
                                            } else {
                                                passwordField.text = "";
                                                passwordField.hint = "Wrong Password! Try again.";
                                                passwordField.hintColor = "#ff3333";
                                                if (result === PamResult.Failed)
                                                    Qt.callLater(() => pamAuth.start());
                                            }
                                        }
                                    }

                                    TextField {
                                        id: passwordField
                                        anchors.fill: parent

                                        property string hint: "Password"
                                        property color hintColor: Qt.rgba(1, 1, 1, 0.5)

                                        echoMode: TextInput.Password
                                        leftPadding: ShellConfig.px(20)
                                        rightPadding: ShellConfig.px(20)
                                        topPadding: ShellConfig.px(10)
                                        bottomPadding: ShellConfig.px(10)
                                        verticalAlignment: TextInput.AlignVCenter

                                        color: passwordBox.maskAvailable ? "transparent" : "white"
                                        selectionColor: passwordBox.maskAvailable ? "transparent" : Colors.primary
                                        selectedTextColor: passwordBox.maskAvailable ? "transparent" : "white"
                                        cursorDelegate: Rectangle {
                                            visible: !passwordBox.maskAvailable && passwordField.cursorVisible
                                            width: ShellConfig.px(2)
                                            color: "white"
                                        }
                                        font.pixelSize: ShellConfig.fontPx(20)

                                        onTextChanged: passwordBox.maskEdits++

                                        Visualisers.PasswordMask {
                                            id: passwordMask
                                            anchors.fill: parent
                                            anchors.leftMargin: passwordField.leftPadding
                                            anchors.rightMargin: passwordField.rightPadding
                                            anchors.topMargin: ShellConfig.px(3)
                                            anchors.bottomMargin: ShellConfig.px(3)
                                            visible: passwordBox.maskAvailable
                                            active: passwordBox.maskAvailable
                                        }

                                        Text {
                                            visible: passwordField.text.length === 0 && passwordField.preeditText.length === 0
                                            x: passwordField.leftPadding
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: passwordField.hint
                                            color: passwordField.hintColor
                                            font: passwordField.font
                                        }

                                        background: Rectangle {
                                            color: Qt.rgba(1, 1, 1, 0.07)
                                            border.color: Qt.rgba(1, 1, 1, 0.14)
                                            border.width: 1
                                            radius: ShellConfig.px(28)
                                        }

                                        onAccepted: submit()

                                        function submit() {
                                            if (text.length > 0) {
                                                if (pamAuth.responseRequired) {
                                                    pamAuth.respond(text);
                                                } else {
                                                    pamAuth.pendingPassword = text;
                                                    if (!pamAuth.active)
                                                        pamAuth.start();
                                                }
                                            }
                                        }
                                        focus: true
                                        Component.onCompleted: forceActiveFocus()
                                    }
                                }

                                Rectangle {
                                    readonly property bool ready: passwordField.text.length > 0

                                    Layout.preferredHeight: ShellConfig.px(56)
                                    implicitWidth: unlockButton.implicitWidth
                                    radius: height / 2
                                    color: ready ? Colors.primary_container : "transparent"
                                    border.width: 1
                                    border.color: Colors.primary

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    RoundButton {
                                        id: unlockButton
                                        anchors.fill: parent
                                        text: "Unlock"
                                        flat: true
                                        topInset: 0
                                        bottomInset: 0
                                        leftInset: 0
                                        rightInset: 0
                                        horizontalPadding: ShellConfig.px(24)
                                        focusPolicy: Qt.NoFocus
                                        Material.theme: Material.Dark
                                        Material.accent: Colors.primary
                                        Material.foreground: parent.ready ? Colors.on_primary_container : "white"
                                        font.pixelSize: ShellConfig.fontPx(20)
                                        onClicked: passwordField.submit()
                                        HoverHandler {
                                            cursorShape: Qt.PointingHandCursor
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: lockSurface.capsLock
                                Layout.alignment: Qt.AlignHCenter
                                text: "⇪  Caps Lock is on"
                                color: "#ffb86b"
                                font.pixelSize: ShellConfig.fontPx(18)
                            }
                        }
                    }
                }
            }
        }
    }
}
