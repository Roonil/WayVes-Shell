import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import qs.config

ScaledRoundButton {
    id: root

    property bool busy: false
    property string busyText: ""

    flat: true

    contentItem: RowLayout {
        spacing: ShellConfig.px(8)

        BusyIndicator {
            visible: root.busy
            running: root.busy
            padding: 0
            implicitWidth: ShellConfig.px(16)
            implicitHeight: ShellConfig.px(16)
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.busy && root.busyText.length > 0 ? root.busyText : root.text
            font: root.font
            color: root.enabled ? root.Material.foreground : root.Material.hintTextColor
            Layout.alignment: Qt.AlignVCenter
        }
    }

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
