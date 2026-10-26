import QtQuick

import Quickshell
import qs.config

QtObject {
    id: root

    property var configObject: undefined

    property real radius: ShellConfig.px(configObject?.radius ?? 1000)
    property real viewTiltAngle: configObject?.viewTiltAngle ?? 75
    property real viewSweepAngle: configObject?.viewSweepAngle ?? 120
    property real sweepAngle: configObject?.sweepAngle ?? 110
    property real verticalAngle: configObject?.verticalAngle ?? 27
    property real indicatorDistance: ShellConfig.px(configObject?.indicatorDistance ?? 10)
    property real indicatorWidthScale: configObject?.indicatorWidthScale ?? 1.2
    property real indicatorHeightScale: configObject?.indicatorHeightScale ?? 1.2
    property real radialDisplacement: ShellConfig.px(configObject?.radialDisplacement ?? -160)
    property real indicatorFloatHeight: ShellConfig.px(configObject?.indicatorFloatHeight ?? 15)
    property real iconFloatHeight: ShellConfig.px(configObject?.iconFloatHeight ?? 20)
    property int iconWidth: ShellConfig.px(configObject?.iconWidth ?? 80)
    property int iconHeight: ShellConfig.px(configObject?.iconHeight ?? 80)
    property real perspectiveDistance: ShellConfig.px(configObject?.perspectiveDistance ?? 2048)

    Behavior on radius {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on viewTiltAngle {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on viewSweepAngle {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on sweepAngle {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on verticalAngle {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on indicatorDistance {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on indicatorWidthScale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on indicatorHeightScale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on radialDisplacement {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on indicatorFloatHeight {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on iconFloatHeight {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on iconWidth {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on iconHeight {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on perspectiveDistance {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    onViewSweepAngleChanged: {
        Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'sweepAngle=${viewSweepAngle}' > /tmp/WayVes/dock`]);
    }


    Component.onCompleted: {
        Quickshell.execDetached(["timeout", "1", "sh", "-c", `echo 'sweepAngle=${viewSweepAngle}' > /tmp/WayVes/dock`]);
    }
}
