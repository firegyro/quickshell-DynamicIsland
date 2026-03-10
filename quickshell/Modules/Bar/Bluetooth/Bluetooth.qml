import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Services
import qs.config

Rectangle {
    id: root

    // --- 样式配置 ---
    color: Colorscheme.background
    radius: Sizes.cornerRadius
    implicitHeight: Sizes.barHeight
    implicitWidth: 35

    // --- 交互逻辑 ---
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            console.log("Action: Launching bluetui via xdg-run")

            // 方式 A: 使用 Quickshell 内置的运行指令 (尝试加上 Runtime 前缀)
            // 如果你的 Quickshell 比较新，尝试：
            Quickshell.execDetached(["kitty", "bluetui"])



            // 方式 C: 如果 A/B 都不行，最原始的办法是调用一个脚本
            // 你可以在后台运行： nohup kitty bluetui > /dev/null 2>&1 &
        }
    }

    // --- 图标显示 ---
    Text {
        anchors.centerIn: parent
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 16

        // 绑定蓝牙 Service 状态
        // 如果 Bluetooth Service 也不可用，请临时改用 "#00aaff" 确保图标能看清
        color: (typeof Bluetooth !== "undefined" && Bluetooth.enabled)
        ? Colorscheme.primary
        : Colorscheme.on_surface_variant

        text: ""

        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
