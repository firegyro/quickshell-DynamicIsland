import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    
    // 【修改】高度减小到 170
    width: 420
    height: 170

    color: "#1E1E1E"
    radius: 24

    property var locale: Qt.locale()
    property date currentTime: new Date()
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.currentTime = new Date() }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        // 时间行
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 15
            
            Text {
                color: "white"
                font.family: "LXGW WenKai GB Screen"
                font.pixelSize: 80 // 【修改】从 100 减小到 80
                font.bold: true
                Layout.alignment: Qt.AlignBaseline
                
                text: {
                    let h = root.currentTime.getHours();
                    let m = root.currentTime.getMinutes();
                    let h12 = h % 12; if (h12 === 0) h12 = 12;
                    let hStr = h12 < 10 ? "0" + h12 : h12;
                    let mStr = m < 10 ? "0" + m : m;
                    return hStr + ":" + mStr;
                }
            }
            Text {
                text: Qt.formatTime(root.currentTime, "ap").toUpperCase()
                color: "#666"
                font.family: "LXGW WenKai GB Screen"
                font.pixelSize: 28 // 【修改】稍微减小
                font.bold: true
                Layout.alignment: Qt.AlignBaseline
            }
        }

        // 日期行
        Text {
            text: Qt.formatDate(root.currentTime, "yyyy/MM/dd dddd")
            color: "#888"
            font.family: "LXGW WenKai GB Screen"
            font.pixelSize: 22 // 【修改】稍微减小
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -5
        }
    }
}
