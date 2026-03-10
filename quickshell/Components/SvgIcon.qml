pragma Singleton
import QtQuick

QtObject {
    // 图标所在的绝对路径
    readonly property string basePath: "/home/archirithm/.config/quickshell/assets/icons/"

    // 注册图标值
    property string previous: basePath + "previous.svg"
    property string play: basePath + "play.svg"
    property string pause: basePath + "pause.svg"
    property string next: basePath + "next.svg"
}
