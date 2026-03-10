import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects 

Rectangle {
    id: root
    
    // 【修改】高度拉长，填补留言板留下的空间
    width: 260
    height: 360

    color: "#1E1E1E"
    radius: 24

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30 // 【修改】增加间距，利用垂直空间

        // 头像区域
        Item {
            Layout.preferredWidth: 140 // 稍微加大头像
            Layout.preferredHeight: 140
            Layout.alignment: Qt.AlignHCenter

            Image {
                id: avatarImg
                anchors.fill: parent
                source: "file:///home/archirithm/Pictures/avatar/shelby.jpg"
                sourceSize: Qt.size(140, 140)
                fillMode: Image.PreserveAspectCrop
                visible: false
                cache: true
            }

            Rectangle {
                id: mask
                anchors.fill: parent
                radius: width / 2
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: avatarImg
                maskSource: mask
            }
            
            // 装饰边框
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: Qt.rgba(1,1,1,0.1)
                border.width: 2
            }
        }

        // 文字区域
        ColumnLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "Archirithm"
                color: "white"
                Layout.alignment: Qt.AlignHCenter
                font.family: "LXGW WenKai GB Screen"
                font.pixelSize: 32 // 字体加大
                font.bold: true
            }

            Text {
                text: "@archbtw"
                color: "#888888"
                Layout.alignment: Qt.AlignHCenter
                font.family: "LXGW WenKai GB Screen"
                font.pixelSize: 18
            }
            
            // 可以在这里加个身份标签，利用空间
            Rectangle {
                Layout.topMargin: 10
                Layout.alignment: Qt.AlignHCenter
                width: 100; height: 26
                color: "#333"
                radius: 13
                Text {
                    anchors.centerIn: parent
                    text: "Student"
                    color: "#ccc"
                    font.family: "LXGW WenKai GB Screen"
                    font.pixelSize: 12
                }
            }
        }
    }
}
