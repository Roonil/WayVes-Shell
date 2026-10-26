import QtQuick

QtObject {

    property real notchWidth: 0
    property real notchHeight: 0

    property real topLeftRadius: 0
    property bool flipTopLeft: false

    property real topRightRadius: 0
    property bool flipTopRight: false

    property real bottomRightRadius: 0
    property bool flipBottomRight: false

    property real bottomLeftRadius: 0
    property bool flipBottomLeft: false

    property real leftSideOverflow: 0
    property real rightSideOverflow: 0
    property real topSideOverflow: 0
    property real bottomSideOverflow: 0

    Behavior on topLeftRadius {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on topRightRadius {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on bottomRightRadius {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on bottomLeftRadius {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
}
