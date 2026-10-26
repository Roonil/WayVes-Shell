import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

import qs.config
import qs.components.notch
import qs.config.theme
import qs.enums

RowLayout {
    id: root
    Material.theme: Colors.isDark ? Material.Dark : Material.Light
    Material.accent: Colors.primary

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    property var trayItems: SystemTray.items

    property var configObject: undefined
    property var isSubMenu: false

    property bool mode: false
    signal requestPanelChange(Component newPanel)


    RowLayout {
        id: rowLayout
        spacing: ShellConfig.px(20)
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

        Repeater {
            id: repeater
            visible: !root.isSubMenu
            enabled: !root.isSubMenu
            model: !root.isSubMenu ? root.trayItems : undefined

            Item {
                implicitHeight: ShellConfig.px(20)
                implicitWidth: ShellConfig.px(20)
                IconImage {
                    id: icon
                    source: modelData.icon
                    anchors.fill: parent
                    mipmap: true

                    backer.sourceSize.width: 25
                    backer.sourceSize.height: 25
                }


                TrayRepeater {

                    anchors.fill: parent
                    repeaterMenu: modelData.menu
                    isSubMenu: root.isSubMenu
                }
            }
        }
    }
    TrayRepeater {
        visible: root.isSubMenu
        enabled: root.isSubMenu
        Layout.fillWidth: true
        Layout.fillHeight: true
        repeaterMenu: root.trayItems
        isSubMenu: root.isSubMenu
    }

    component TrayRepeater: ColumnLayout {
        id: trayRepeater
        property var repeaterMenu: undefined
        property bool isSubMenu: false
        Loader {
            id: menuLoader
            active: !root.isSubMenu
            sourceComponent: QsMenuOpener {
                id: menuAnchorFromLoader
                menu: trayRepeater.repeaterMenu
            }
        }
        QsMenuOpener {
            id: menuAnchor
            menu: trayRepeater.repeaterMenu
        }
        property var menuChildren: menuAnchor.children

        Connections {
            target: trayRepeater.repeaterMenu
            ignoreUnknownSignals: true

            function onMenuChanged() {
                menuLoader.active = false;
                menuLoader.active = true;
            }
        }

        TrayContent {
            visible: root.isSubMenu
            enabled: root.isSubMenu
            Layout.fillWidth: true
            Layout.fillHeight: true

            items: root.isSubMenu ? menuChildren : undefined

            onLayoutUpdated: () => {
                trayRepeater.repeaterMenu.menuChanged();
            }
        }

        Component {
            id: componentWrapper
            TrayContent {
                visible: !root.isSubMenu
                enabled: !root.isSubMenu
                Layout.fillWidth: true
                Layout.fillHeight: true
                items: !root.isSubMenu ? menuChildren : undefined
                onLayoutUpdated: () => {
                    trayRepeater.repeaterMenu.menuChanged();
                }
            }
        }

        HoverHandler {
            blocking: false
            cursorShape: Qt.PointingHandCursor

            onHoveredChanged: {
                if (!hovered || root.isSubMenu)
                    return;

                root.requestPanelChange(componentWrapper);
            }
        }
    }

    component TrayContent: ColumnLayout {
        id: trayContent
        property var items: undefined
        signal layoutUpdated

        Pane {
            id: trayPane
            padding: ShellConfig.px(12)
            Layout.margins: 0
            Layout.fillWidth: true
            background: Rectangle {
                color: "transparent"
            }
            ColumnLayout {
                spacing: ShellConfig.px(12)
                anchors.fill: parent
                Repeater {
                    id: menuEntry
                    model: items

                    delegate: Pane {
                        id: backgroundPane
                        property var trayItem: modelData

                        padding: 0

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignTop

                        background: Rectangle {
                            Layout.alignment: Qt.AlignRight
                            anchors.fill: parent
                            anchors.centerIn: parent

                            color: trayItem.isSeparator ? Colors.outline : "transparent"
                            border.width: 1
                            border.color: Colors.outline
                            radius: ShellConfig.px(40)
                        }
                        Component {
                            id: radioButton
                            RadioButton {
                                id: trayRadio
                                verticalPadding: ShellConfig.px(6)
                                Binding {
                                    target: trayRadio.indicator
                                    property: "scale"
                                    value: ShellConfig.sizeScale
                                }
                                font.pixelSize: ShellConfig.fontPx(14)
                                Material.theme: Colors.isDark ? Material.Dark : Material.Light
                                Material.accent: Colors.primary
                                checked: trayItem.checkState === Qt.Checked
                                padding: 0
                                onToggled: {
                                    checked = Qt.binding(() => trayItem.checkState === Qt.Checked);
                                    trayItem.triggered();

                                    trayItem.updateLayout();

                                    trayContent.layoutUpdated();
                                }
                            }
                        }

                        Component {
                            id: checkBox
                            RowLayout {

                                CheckBox {
                                    id: trayCheckBox
                                    verticalPadding: ShellConfig.px(6)
                                    Binding {
                                        target: trayCheckBox.indicator
                                        property: "scale"
                                        value: ShellConfig.sizeScale
                                    }
                                    font.pixelSize: ShellConfig.fontPx(14)
                                    Material.theme: Colors.isDark ? Material.Dark : Material.Light
                                    Material.accent: Colors.primary
                                    checked: trayItem.checkState === Qt.Checked
                                    padding: 0
                                    onToggled: {
                                        checked = Qt.binding(() => trayItem.checkState === Qt.Checked);
                                        trayItem.triggered();

                                        trayItem.updateLayout();

                                        trayContent.layoutUpdated();
                                    }

                                }

                                Loader {
                                    Layout.fillWidth: true
                                    sourceComponent: text
                                }
                            }
                        }

                        Component {
                            id: separator
                            Item {}
                        }
                        Component {
                            id: text
                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                                    text: trayItem.text
                                    color: Colors.on_surface
                                    anchors.verticalCenter: parent.verticalCenter


                                }
                            }
                        }

                        Component {
                            id: nestedMenu
                            Item {
                                id: nestedMenuItem
                                property bool hovered: false
                                Text {
                                    font.pointSize: ShellConfig.defaultPointSize * ShellConfig.fontScale
                                    id: text
                                    text: trayItem.text
                                    color: Colors.on_surface
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item {

                                    anchors.top: parent.top
                                    transform: Translate {
                                        x: -(trayPane.leftPadding ?? trayPane.horizontalPadding ?? trayPane.padding ?? 0) - translate.x
                                        y: ShellConfig.px(-38)
                                    }
                                    Notch {
                                        id: notch
                                        childIsHovered: nestedMenuItem.hovered
                                        checkParentBottomLeftOverflow: true

                                        configObject: root.configObject
                                        anchors.top: parent.top
                                        anchors.right: parent.right

                                        direction: Directions.Left

                                        panelContent: Loader {
                                            active: trayItem.hasChildren

                                            onLoaded: {
                                                item.trayItems = trayItem;
                                                item.isSubMenu = true;
                                            }
                                            source: "SystemTrayCard.qml"
                                        }
                                        headerContent: ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Rectangle {
                                                width: ShellConfig.px(10)
                                                height: ShellConfig.px(10)
                                                radius: ShellConfig.px(20)
                                                color: Colors.primary
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RoundButton {
                            id: button
                            visible: !trayItem.isSeparator
                            anchors.verticalCenter: parent.verticalCenter

                            implicitHeight: trayItem.isSeparator ? 1 : ShellConfig.px(36)
                            anchors.left: parent.left
                            anchors.right: parent.right
                            topInset: 0

                            bottomInset: 0
                            leftInset: 0
                            rightInset: 0
                            radius: ShellConfig.px(20)
                            verticalPadding: 0

                            flat: true
                            onClicked: {
                                trayItem.triggered();

                                trayItem.updateLayout();

                                trayContent.layoutUpdated();
                            }

                            contentItem: Loader {
                                id: trayItemsLoader
                                visible: !trayItem.isSeparator && !trayItem.hasChildren
                                anchors.centerIn: parent
                                sourceComponent: trayItem.hasChildren ? nestedMenu : trayItem.buttonType === QsMenuButtonType.CheckBox ? checkBox : trayItem.buttonType === QsMenuButtonType.RadioButton ? radioButton : trayItem.isSeparator ? separator : text

                                HoverHandler {
                                    blocking: false
                                    onHoveredChanged: {
                                        if (!trayItem.hasChildren)
                                            return;

                                        trayItemsLoader.item.hovered = hovered;
                                    }
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }

                            Loader {
                                transform: Translate {
                                    id: translate
                                    x: ShellConfig.px(12)
                                }
                                anchors.verticalCenter: parent.verticalCenter
                                visible: trayItem.hasChildren
                                sourceComponent: nestedMenu
                            }
                        }
                    }
                }
            }
        }
    }
}
