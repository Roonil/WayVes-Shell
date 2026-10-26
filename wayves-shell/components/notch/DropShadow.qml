import QtQuick
import qs.config.theme

QtObject {
    property bool enabled: true
    property real leftExtent: 0
    property real rightExtent: 0
    property real topExtent: 0
    property real bottomExtent: 0

    property real verticalOffset: 0
    property real horizontalOffset: 0
    property real blur: 32
    property real spread: 0
    property color color: 'black'
    property bool applyToShape: true
}
