import QtQuick
import QtQuick.Controls.Material
import qs.config

RoundButton {
    id: root

    font.pixelSize: ShellConfig.fontPx(14)
    padding: ShellConfig.px(12)
    topInset: ShellConfig.px(6)
    bottomInset: ShellConfig.px(6)
    leftInset: ShellConfig.px(6)
    rightInset: ShellConfig.px(6)
    implicitWidth: Math.max(ShellConfig.px(root.Material.buttonHeight) + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(ShellConfig.px(root.Material.buttonHeight) + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding)
}
