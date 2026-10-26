import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.config
import qs.config.theme
import qs.shell.lockscreen
import qs.Visualisers

ShellRoot {
    id: shellRoot
    property var configObject: undefined
    signal toggled(bool toggle)

    PanelWindow {
        id: root
        property bool isVisible: false
        visible: false
        anchors.left: true

        onIsVisibleChanged: {
            shellRoot.toggled(isVisible);
            actionsHolder.cancelPending();
            if (isVisible) {
                actionsHolder.currentIndex = 0;
                actionsHolder.forceActiveFocus();
            }
        }

        color: 'transparent'
        mask: root.isVisible ? null : hideInput

        Region {
            id: hideInput
            width: 0
            height: 0
        }

        Region {
            id: itemRegion
            item: actionsHolder
        }

        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "power-menu"
        implicitHeight: Quickshell.screens[0].height
        implicitWidth: ShellConfig.px(1500)

        WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: rootItem
            IpcHandler {
                target: "showPowerMenu"
                function toggle() {
                    root.isVisible = !root.isVisible;
                }

                function on() {
                    root.isVisible = true;
                }
                function off() {
                    root.isVisible = false;
                }
            }
            anchors.fill: parent

            Visualisers.Hud {
                anchors.fill: parent
                active: root.isVisible
                visible: root.isVisible
                type: "surface"
                transform: Translate {
                    x: -root.implicitWidth / 2 - (!root.isVisible ? root.width / 2 : 0)
                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuint
                        }
                    }
                }
            }

            Visualisers.Hud {
                anchors.fill: parent
                active: root.isVisible
                visible: root.isVisible
                type: "outer_ring"

                transform: Translate {
                    x: -root.implicitWidth / 2 - (!root.isVisible ? root.width / 2 : 0)
                    Behavior on x {
                        NumberAnimation {
                            duration: 900
                            easing.type: Easing.OutQuint
                            onRunningChanged: {
                                if (running) {
                                    if (root.isVisible)
                                        root.visible = true;
                                } else {
                                    if (!root.isVisible)
                                        root.visible = false;
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: root.implicitWidth / 2
                height: root.implicitHeight / 2
                anchors.right: parent.right
                Visualisers.Hud {
                    anchors.fill: parent
                    active: root.isVisible
                    visible: root.isVisible
                    type: "waves"
                    transform: Translate {
                        x: -root.implicitWidth / 2 - (!root.isVisible ? root.width / 2 : 0)
                        Behavior on x {
                            NumberAnimation {
                                duration: 700
                                easing.type: Easing.OutQuint
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: actionsHolder
                anchors.centerIn: parent
                focus: true
                transform: [
                    Translate {
                        x: -root.implicitWidth / 2 - (!root.isVisible ? root.width / 2 : 0)
                        Behavior on x {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutQuint
                            }
                        }
                    },
                    Translate {
                        x: ShellConfig.px(250)
                    }
                ]
                Process {
                    id: shellExecutor
                }

                property int currentIndex: 0

                property int pendingIndex: -1
                property int secondsLeft: 0
                property real pendingProgress: 0

                function activate(index) {
                    if (index === pendingIndex) {
                        runPending();
                        return;
                    }
                    cancelPending();
                    let entry = actions[index];
                    if (entry.countdown <= 0) {
                        entry.action();
                        return;
                    }
                    pendingIndex = index;
                    secondsLeft = entry.countdown;
                    countdownTimer.restart();
                    progressAnimation.duration = entry.countdown * 1000;
                    progressAnimation.restart();
                }

                function runPending() {
                    let entry = actions[pendingIndex];
                    cancelPending();
                    entry.action();
                }

                function cancelPending() {
                    countdownTimer.stop();
                    progressAnimation.stop();
                    pendingIndex = -1;
                    pendingProgress = 0;
                }

                function select(index) {
                    currentIndex = Math.max(0, Math.min(actions.length - 1, index));
                }

                Timer {
                    id: countdownTimer
                    interval: 1000
                    repeat: true
                    onTriggered: {
                        actionsHolder.secondsLeft--;
                        if (actionsHolder.secondsLeft <= 0)
                            actionsHolder.runPending();
                    }
                }

                NumberAnimation {
                    id: progressAnimation
                    target: actionsHolder
                    property: "pendingProgress"
                    from: 1
                    to: 0
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Up:
                        currentIndex = (currentIndex - 1 + actions.length) % actions.length;
                        break;
                    case Qt.Key_Down:
                        currentIndex = (currentIndex + 1) % actions.length;
                        break;
                    case Qt.Key_Home:
                    case Qt.Key_PageUp:
                        select(0);
                        break;
                    case Qt.Key_End:
                    case Qt.Key_PageDown:
                        select(actions.length - 1);
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space:
                        activate(currentIndex);
                        break;
                    case Qt.Key_Escape:
                        if (pendingIndex >= 0)
                            cancelPending();
                        else
                            root.isVisible = false;
                        break;
                    default:
                        return;
                    }
                    event.accepted = true;
                }

                property list<QtObject> actions: [
                    QtObject {
                        property var name: "Shut Down"
                        property string pendingName: "Shutting down"
                        property int countdown: ShellConfig.configObject?.powerMenu?.countdowns?.shutdown ?? 5
                        property var action: function () {
                            root.isVisible = false;

                            shellExecutor.command = ["systemctl", "poweroff"];
                            shellExecutor.running = true;
                        }
                    },
                    QtObject {
                        property var name: "Reboot"
                        property string pendingName: "Rebooting"
                        property int countdown: ShellConfig.configObject?.powerMenu?.countdowns?.reboot ?? 5
                        property var action: function () {
                            root.isVisible = false;

                            shellExecutor.command = ["systemctl", "reboot"];
                            shellExecutor.running = true;
                        }
                    },
                    QtObject {
                        property var name: "Log Out"
                        property string pendingName: "Logging out"
                        property int countdown: ShellConfig.configObject?.powerMenu?.countdowns?.logout ?? 5
                        property var action: function () {
                            root.isVisible = false;
                            shellExecutor.command = ["hyprctl", "dispatch", "exit"];
                            shellExecutor.running = true;
                        }
                    },
                    QtObject {
                        property var name: "Lock"
                        property string pendingName: "Locking"
                        property int countdown: ShellConfig.configObject?.powerMenu?.countdowns?.lock ?? 0
                        property var action: function () {
                            root.isVisible = false;
                            lockLoader.active = true;
                        }
                    },
                    QtObject {
                        property var name: "Exit"
                        property string pendingName: ""
                        property int countdown: 0
                        property var action: function () {
                            root.isVisible = false;
                        }
                    }
                ]

                Repeater {
                    model: actionsHolder.actions

                    delegate: Item {
                        id: entry
                        readonly property bool selected: index === actionsHolder.currentIndex
                        readonly property bool pending: index === actionsHolder.pendingIndex

                        width: label.implicitWidth
                        height: label.implicitHeight
                        Text {
                            id: label
                            font {
                                family: "Race Sport"
                            }
                            font.pixelSize: ShellConfig.fontPx(60)
                            text: modelData.name
                            color: Colors.on_surface

                            scale: entry.selected ? 1.05 : 1.0
                            x: entry.selected ? ShellConfig.px(60) : 0
                            Behavior on x {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuint
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuint
                                }
                            }
                        }

                        Rectangle {
                            visible: entry.pending
                            x: label.x
                            anchors.bottom: label.bottom
                            height: ShellConfig.px(4)
                            radius: ShellConfig.px(2)
                            width: label.width * actionsHolder.pendingProgress
                            color: Colors.primary
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: actionsHolder.currentIndex = index
                            onClicked: actionsHolder.activate(index)
                        }
                    }
                }

                Item {
                    Layout.preferredHeight: 0
                    Layout.topMargin: -actionsHolder.spacing
                    Layout.fillWidth: true

                    Text {
                        y: ShellConfig.px(24)
                        x: ShellConfig.px(4)
                        opacity: actionsHolder.pendingIndex >= 0 ? 0.8 : 0
                        text: (actionsHolder.pendingIndex >= 0 ? actionsHolder.actions[actionsHolder.pendingIndex].pendingName + " in " + actionsHolder.secondsLeft + "\n" : "") + "Enter or click again to do it now  ·  Esc to cancel"
                        color: Colors.on_surface
                        font.pixelSize: ShellConfig.fontPx(18)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }
            }

            HoverHandler {
                onHoveredChanged: if (!hovered)
                    root.isVisible = false
            }
        }
    }
    Loader {
        id: lockLoader
        active: false
        sourceComponent: LockScreen {
            configObject: shellRoot.configObject
            onChangeLockState: locked => {
                lockLoader.active = locked;
            }
        }
    }
}
