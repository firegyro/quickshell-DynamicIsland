import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

Item {
    id: root
    required property var audioNode

    readonly property real volume: audioNode ? audioNode.volume : 0
    readonly property bool isMuted: audioNode ? audioNode.muted : false

    RowLayout {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 12

        // 左侧：静音图标（点击切换）
        Item {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 18
                text: root.isMuted ? "🔇" : ""
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.audioNode) root.audioNode.muted = !root.audioNode.muted
            }
        }

        // 中间：音量进度条
        Rectangle {
            id: barContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            Layout.alignment: Qt.AlignVCenter

            color: Colorscheme.background
            radius: 3
            clip: true  // ← 修复：防止填充矩形超出容器边界

            Rectangle {
                height: parent.height
                radius: 3
                color: "white"
                // ← 修复：用 Math.min 保证不超过父宽度
                width: Math.min(Math.max(0, root.volume * parent.width), parent.width)

                Behavior on width {
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 80 }
                }
            }

            MouseArea {
                id: dragArea
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 20

                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function setVol(mouseX) {
                    if (!root.audioNode) return
                        let p = mouseX / width
                        if (p < 0) p = 0
                            if (p > 1) p = 1
                                root.audioNode.volume = p
                                if (root.isMuted) root.audioNode.muted = false
                }

                onPressed: (mouse) => setVol(mouse.x)
                onPositionChanged: (mouse) => setVol(mouse.x)
            }
        }

        // 右侧：音量百分比（与左侧图标宽度对称）
        Text {
            Layout.preferredWidth: 36
            Layout.alignment: Qt.AlignVCenter
            color: "white"
            font.pixelSize: 12
            // 静音时显示 0%，否则显示实际百分比
            text: root.isMuted ? "0%" : Math.round(root.volume * 100) + "%"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
