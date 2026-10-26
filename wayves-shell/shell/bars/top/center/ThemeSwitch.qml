import QtQuick

import qs.config
import qs.config.theme
import qs.Visualisers

Item {
    id: root

    readonly property real orbSize: ShellConfig.px(40)
    readonly property real orbitSize: ShellConfig.px(68)
    readonly property int halfTurnDuration: 220

    property bool active: true
    readonly property bool visualiserAvailable: themeButton.ready

    property bool shownDark: false
    property real markerTarget: -45
    property real markerAngle: markerTarget

    Component.onCompleted: {
        shownDark = Theme.isDark;
        markerTarget = Theme.isDark ? 135 : -45;
        markerBehavior.enabled = true;
    }

    implicitWidth: orbitSize + ShellConfig.px(8)
    implicitHeight: orbitSize + ShellConfig.px(8) + label.height + ShellConfig.px(6)

    Connections {
        target: Theme
        function onIsDarkChanged() {
            root.markerTarget += 180;
            if (Theme.isDark !== root.shownDark)
                turnOver.restart();
        }
    }

    Item {
        id: dial
        width: root.orbitSize + ShellConfig.px(8)
        height: width
        scale: hover.hovered ? 1.08 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: system
            anchors.fill: parent

            transform: Rotation {
                id: flip
                origin.x: system.width / 2
                origin.y: system.height / 2
                axis {
                    x: 1
                    y: 0
                    z: 0
                }
            }

            Item {
                anchors.fill: parent

                Visualisers.ThemeButton {
                    id: themeButton
                    anchors.centerIn: parent
                    width: parent.width + ShellConfig.px(30)
                    height: parent.height + ShellConfig.px(30)
                    visible: root.visualiserAvailable
                    active: root.visualiserAvailable && root.active
                }
            }

            Repeater {
                model: root.visualiserAvailable ? 0 : 28

                Rectangle {
                    readonly property real angle: index / 28 * 2 * Math.PI
                    width: ShellConfig.px(2)
                    height: ShellConfig.px(2)
                    radius: 1
                    x: dial.width / 2 + Math.cos(angle) * root.orbitSize / 2 - 1
                    y: dial.height / 2 + Math.sin(angle) * root.orbitSize / 2 - 1
                    color: Colors.on_surface
                    opacity: hover.hovered ? 0.7 : 0.4

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }
                }
            }

            Rectangle {
                id: orb
                visible: !root.visualiserAvailable
                anchors.centerIn: parent
                width: root.orbSize
                height: root.orbSize
                radius: width / 2
                color: root.shownDark ? "white" : "#ffd23f"
            }
        }

        Rectangle {
            visible: !root.visualiserAvailable
            readonly property real angle: root.markerAngle * Math.PI / 180
            width: ShellConfig.px(6)
            height: ShellConfig.px(6)
            radius: ShellConfig.px(3)
            x: dial.width / 2 + Math.cos(angle) * root.orbitSize / 2 - width / 2
            y: dial.height / 2 + Math.sin(angle) * root.orbitSize / 2 - height / 2
            color: Colors.primary
        }

        SequentialAnimation {
            id: turnOver

            ParallelAnimation {
                NumberAnimation {
                    target: flip
                    property: "angle"
                    to: 90
                    duration: root.halfTurnDuration
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: label
                    property: "opacity"
                    to: 0
                    duration: root.halfTurnDuration
                }
            }
            ScriptAction {
                script: {
                    root.shownDark = Theme.isDark;
                    Colors.updateWayVesColors("isDarkMode=" + root.shownDark, "angular_theme_button");
                    flip.angle = -90;
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: flip
                    property: "angle"
                    to: 0
                    duration: root.halfTurnDuration
                    easing.type: Easing.OutBack
                }
                NumberAnimation {
                    target: label
                    property: "opacity"
                    to: 0.7
                    duration: root.halfTurnDuration
                }
            }
        }
    }

    Behavior on markerAngle {
        id: markerBehavior
        enabled: false

        NumberAnimation {
            duration: root.halfTurnDuration * 2
            easing.type: Easing.InOutCubic
        }
    }

    Text {
        id: label
        anchors.top: dial.bottom
        anchors.topMargin: ShellConfig.px(6)
        anchors.horizontalCenter: dial.horizontalCenter
        text: root.shownDark ? "NIGHT" : "DAY"
        color: Colors.on_surface
        opacity: 0.7
        font.pixelSize: ShellConfig.fontPx(12)
        font.weight: Font.DemiBold
        font.letterSpacing: 2.5
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: Theme.updateThemeMode(!Theme.isDark)
    }
}
