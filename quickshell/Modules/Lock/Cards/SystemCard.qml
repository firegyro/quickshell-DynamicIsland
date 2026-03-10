import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    
    // 保持你调整后的尺寸
    width: 420
    height: 110
    
    color: "#1E1E1E"
    radius: 24

    // ================== 数据属性定义 ==================
    property real ramProgress: 0
    property real diskProgress: 0
    property real batProgress: 1.0
    property bool isCharging: false
    property real volProgress: 0
    property bool isMuted: false

    // ================== 1. 内存监测 (RAM) [已补全] ==================
    Process {
        id: ramProc
        // 计算内存占用百分比
        command: ["bash", "-c", "grep -E 'MemTotal|MemAvailable' /proc/meminfo | awk '{if($1==\"MemTotal:\") t=$2; else a=$2} END {print 1-a/t}'"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                let val = parseFloat(data);
                if (!isNaN(val)) root.ramProgress = val;
            }
        }
    }
    Timer { running: true; interval: 5000; repeat: true; onTriggered: ramProc.running = true }

    // ================== 2. 磁盘监测 (Disk) [已补全] ==================
    Process {
        id: diskProc
        // 获取根目录占用百分比
        command: ["bash", "-c", "df / --output=pcent | tail -1 | tr -dc '0-9'"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                let val = parseInt(data);
                if (!isNaN(val)) root.diskProgress = val / 100.0;
            }
        }
    }
    Timer { running: true; interval: 60000; repeat: true; onTriggered: diskProc.running = true }

    // ================== 3. 音量监测 (Volume) [已补全] ==================
    Process {
        id: volProc
        // 使用 wpctl 获取音量
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                let d = data.trim();
                // 输出示例: "Volume: 0.45 [MUTED]"
                root.isMuted = d.includes("MUTED");
                let parts = d.split(" ");
                // 有时候格式可能是 "Volume: 0.45"，有时候带 [MUTED]
                // 简单的解析逻辑：找到数字部分
                for (let i = 0; i < parts.length; i++) {
                    let val = parseFloat(parts[i]);
                    if (!isNaN(val) && parts[i].includes(".")) { // 简单的启发式：找带小数点的
                         root.volProgress = val;
                         break;
                    }
                }
            }
        }
    }
    Timer { running: true; interval: 2000; repeat: true; onTriggered: volProc.running = true }

    // ================== 4. 电池监测 (Battery) [保留] ==================
    Process {
        id: batProc
        command: ["bash", "-c", "
            BAT=$(ls /sys/class/power_supply/ | grep '^BAT' | head -n 1);
            if [ -z \"$BAT\" ]; then echo \"100 Discharging\"; else
                CAP=$(cat /sys/class/power_supply/$BAT/capacity);
                STATUS=$(cat /sys/class/power_supply/$BAT/status);
                echo \"$CAP $STATUS\";
            fi
        "]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                let parts = data.trim().split(" ");
                if (parts.length >= 1) {
                    root.batProgress = parseInt(parts[0]) / 100.0;
                    if (parts.length >= 2) {
                        root.isCharging = (parts[1] === "Charging" || parts[1] === "Full");
                    }
                }
            }
        }
    }
    Timer { running: true; interval: 10000; repeat: true; onTriggered: batProc.running = true }

    // ================== 界面布局 (UI) ==================
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 40 
        anchors.rightMargin: 40
        spacing: 20

        // 1. RAM (紫色)
        ProgressCircle {
            icon: "" 
            value: root.ramProgress
            accentColor: "#C586C0" 
        }

        // 2. Volume (蓝色)
        ProgressCircle {
            icon: root.isMuted ? "" : ""
            value: root.volProgress
            accentColor: "#569CD6" 
        }

        // 3. Battery (绿色)
        ProgressCircle {
            icon: root.isCharging ? "" : ""
            value: root.batProgress
            accentColor: "#4EC9B0" 
        }

        // 4. Disk (黄色)
        ProgressCircle {
            icon: "" 
            value: root.diskProgress
            accentColor: "#DCDCAA" 
        }
    }

    // ================== 组件：圆形进度条 ==================
    component ProgressCircle: Item {
        id: comp
        property string icon: ""
        property real value: 0.0
        property color accentColor: "white"

        Layout.preferredWidth: 65
        Layout.preferredHeight: 65
        Layout.alignment: Qt.AlignVCenter

        // 轨道
        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(1, 1, 1, 0.1)
                strokeWidth: 8
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: comp.width / 2; centerY: comp.height / 2
                    radiusX: (comp.width / 2) - 4; radiusY: (comp.height / 2) - 4
                    startAngle: 0; sweepAngle: 360
                }
            }
        }

        // 进度
        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            rotation: -90
            ShapePath {
                fillColor: "transparent"
                strokeColor: comp.accentColor
                strokeWidth: 8
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: comp.width / 2; centerY: comp.height / 2
                    radiusX: (comp.width / 2) - 4; radiusY: (comp.height / 2) - 4
                    startAngle: 0; sweepAngle: 360 * comp.value
                }
            }
        }

        // 图标
        Text {
            anchors.centerIn: parent
            text: comp.icon
            color: "white"
            font.family: "JetBrainsMono Nerd Font" 
            font.pixelSize: 24
        }
    }
}
