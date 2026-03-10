import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Services
import qs.config

Item {
    id: root

    // 控制开关属性
    property bool isOpen: false

    // 使用 Popup 组件，它会自动处理层级，确保显示在最顶层
    Popup {
        id: popup
        visible: root.isOpen
        width: 260
        padding: 16

        // 设置弹出动画
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150 }
            NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 150 }
        }

        // 点击外部区域或按 Esc 自动关闭
        closePolicy: Popup.CloseOnEscape | Popup.OuterKeyPressed | Popup.CloseOnPressOutside
        onClosed: root.isOpen = false

        // 面板背景样式
        background: Rectangle {
            color: Colorscheme.surface
            radius: Sizes.cornerRadius
            border.color: Colorscheme.outline
            border.width: 1
        }

        // 面板内容布局
        contentItem: ColumnLayout {
            spacing: 16

            // 头部：标题 + 状态小点
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "蓝牙设置"
                    font.bold: true
                    font.pixelSize: 16
                    color: Colorscheme.on_surface
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: Bluetooth.enabled ? "#50fa7b" : "#ff5555"
                }
            }

            // 中部：主开关控制
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: Bluetooth.enabled ? "蓝牙已开启" : "蓝牙已关闭"
                    color: Colorscheme.on_surface_variant
                    Layout.fillWidth: true
                }
                Switch {
                    checked: Bluetooth.enabled
                    onToggled: {
                        // 调用 Service 层的开关逻辑
                        Bluetooth.enabled = !Bluetooth.enabled
                    }
                }
            }

            // 底部：当前连接状态
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colorscheme.outline_variant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "当前连接"
                    font.pixelSize: 12
                    color: Colorscheme.outline
                }

                Text {
                    text: Bluetooth.enabled && Bluetooth.connectedDevice
                    ? Bluetooth.connectedDevice
                    : (Bluetooth.enabled ? "未连接任何设备" : "请先开启蓝牙")
                    color: Colorscheme.on_surface
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}
