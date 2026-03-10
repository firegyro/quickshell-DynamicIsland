import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.Services
import qs.config
// import qs.Components // 已移除
// import qs.Config     // 已移除

Rectangle {
    id: rectangle
    
    color: Colorscheme.background 
    
    implicitHeight: Sizes.barHeight
    implicitWidth: content.width + 24 // 内容宽度 + 左右各 12px 的内边距
    
    radius: Sizes.cornerRadius


    // 最外层 RowLayout，让日期和时间左右排列
    RowLayout {
        id: content
        anchors.centerIn: parent // 居中显示
        spacing: 12 // 日期和时间之间的间距

        // --- 左侧：日期 (月 日) ---
        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter // 垂直居中

            Text {
                Layout.alignment: Qt.AlignBaseline // 基线对齐
                font.pointSize: 12
                font.bold: true
                text: Time.month
                
                color: "#a0a0a0" 
            }
            Text {
                Layout.alignment: Qt.AlignBaseline
                font.pointSize: 12
                font.bold: true
                text: Time.day
                
                color: "#ffffff"
            }
        }

        // --- 中间：分割线 (竖线) ---
        Rectangle {
            implicitWidth: 1
            implicitHeight: 18
            
            color: "#ffffff"
            opacity: 0.3 // 保持透明度
            Layout.alignment: Qt.AlignVCenter
        }

        // --- 右侧：时间 (HH:MM) ---
        RowLayout {
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            Text {
                Layout.alignment: Qt.AlignBaseline
                font.pointSize: 14 
                font.bold: true
                text: Time.hours
                
                color: "#a0a0a0" 
            }
            
            // 手动加个冒号
            Text {
                Layout.alignment: Qt.AlignBaseline
                font.pointSize: 14
                font.bold: true
                text: ":"
                
                color: "#ffffff" 
                Layout.bottomMargin: 1 
            }

            Text {
                Layout.alignment: Qt.AlignBaseline
                font.pointSize: 14
                font.bold: true
                text: Time.minutes
                
                color: "#ffffff" 
            }
        }
    }
}
