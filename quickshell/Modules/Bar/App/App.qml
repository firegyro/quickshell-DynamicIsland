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
            // 修改后的执行命令：调用 dms 的 IPC 接口切换 Spotlight
            console.log("Action: Toggling Spotlight via dms ipc")

            // 使用 Quickshell.execDetached 异步执行命令
            Quickshell.execDetached(["dms", "ipc", "call", "spotlight", "toggle"])
        }
    }

    // --- 图标显示 ---
    Text {
        anchors.centerIn: parent
        // 改为搜索图标 (Font Awesome 的搜索图标通常是 \uf002)
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 16

        // 既然是 Spotlight 开关，通常保持高亮色或主色调
        color: Colorscheme.primary

        text: "" // Unicode 字符，对应搜索放大镜

        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
