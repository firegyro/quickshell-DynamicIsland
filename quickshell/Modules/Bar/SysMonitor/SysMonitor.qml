import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config

Rectangle {
    id: root

    // ================= 1. 样式与尺寸修复 =================
    color: Colorscheme.background
    radius: Sizes.cornerRadius
    clip: true // 关键：必须严格裁剪，否则滚动出的文字会重叠在状态栏其他位置

    property int barHeight: Sizes.barHeight

    // 明确固定宽度，防止内容切换时长短不一导致布局抖动
    Layout.preferredWidth: 100
    Layout.preferredHeight: barHeight

    // ================= 2. 数据处理 (保持不变) =================
    property string ramText: "..."
    property string cpuText: "0%"
    property string tempText: "0°C"
    property string diskText: "0%"
    property string battText: "0%"
    property int battValue: 0
    property bool isCharging: false

    Process {
        id: proc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/sys_monitor.py"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    let json = JSON.parse(data.trim());
                    root.ramText = json.ram.text;
                    root.cpuText = json.cpu.text;
                    root.tempText = json.temp.text;
                    root.diskText = json.disk.text;
                    root.battText = json.batt ? json.batt.text : "N/A";
                    root.battValue = json.batt ? (parseInt(json.batt.text) || 0) : 0;
                    root.isCharging = json.batt ? (json.batt.is_charging || false) : false;
                } catch(e) { console.log("JSON Error: " + e) }
            }
        }
    }

    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }

    // ================= 3. 滚动逻辑优化 =================
    property int rollingIndex: 0
    Timer {
        interval: 3500; running: true; repeat: true
        onTriggered: rollingIndex = (rollingIndex + 1) % 5
    }

    // ================= 4. 视觉组件修复 =================
    // 使用一个内部容器来确保所有滚动项都居中
    Item {
        id: scrollContainer
        anchors.fill: parent
        // 增加一点内边距，防止文字贴边
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        // 统一的滚动子项模板
        component RollingItem: Row {
            width: scrollContainer.width
            height: scrollContainer.height
            spacing: 8

            // 垂直居中修正
            topPadding: (height - contentHeight) / 2
            property int contentHeight: 16 // 预估文本高度

            property int myIndex: 0

            // 改进的坐标逻辑：只有当前项在 0，其他的根据索引差决定在上还是在下
            y: {
                if (rollingIndex === myIndex) return 0;
                if (rollingIndex > myIndex) return -height; // 向上滑出
                return height; // 从下候场
            }

            opacity: rollingIndex === myIndex ? 1 : 0

            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }

        // --- 0. 电量 ---
        RollingItem {
            myIndex: 0
            Text { text: root.isCharging ? "󱐋" : (root.battValue < 20 ? "" : ""); color: "#a6e3a1"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter }
            Text { text: root.battText; color: "white"; font.bold: true; font.pixelSize: 13; font.family: "LXGW WenKai GB Screen"; verticalAlignment: Text.AlignVCenter }
        }

        // --- 1. 内存 ---
        RollingItem {
            myIndex: 1
            Text { text: ""; color: "#89b4fa"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
            Text { text: root.ramText; color: "white"; font.bold: true; font.pixelSize: 13; font.family: "LXGW WenKai GB Screen" }
        }

        // --- 2. CPU ---
        RollingItem {
            myIndex: 2
            Text { text: ""; color: "#fab387"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
            Text { text: root.cpuText; color: "white"; font.bold: true; font.pixelSize: 13; font.family: "LXGW WenKai GB Screen" }
        }

        // --- 3. 温度 ---
        RollingItem {
            myIndex: 3
            Text { text: ""; color: "#f38ba8"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
            Text { text: root.tempText; color: "white"; font.bold: true; font.pixelSize: 13; font.family: "LXGW WenKai GB Screen" }
        }

        // --- 4. 硬盘 ---
        RollingItem {
            myIndex: 4
            Text { text: ""; color: "#cba6f7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
            Text { text: root.diskText; color: "white"; font.bold: true; font.pixelSize: 13; font.family: "LXGW WenKai GB Screen" }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rollingIndex = (rollingIndex + 1) % 5
    }
}
