import QtQuick
import Quickshell
import qs.config

MouseArea {
    id: root
    required property var modelData 
    
    implicitWidth: 24
    implicitHeight: 24
    
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    // --- 互斥逻辑 ---
    // 定义一个函数，供外部（兄弟节点）调用以关闭本菜单
    function closeMenu() {
        if (trayMenu.visible) {
            trayMenu.visible = false
        }
    }

    // 关闭其他兄弟菜单的函数
    function closeOtherMenus() {
        // root.parent 是 RowLayout (在 Tray.qml 中)
        // root.parent.children 包含了所有的 TrayItem (Repeater 创建的 delegate)
        var siblings = root.parent.children
        for (var i = 0; i < siblings.length; i++) {
            var sibling = siblings[i]
            // 如果是自己，跳过
            if (sibling === root) continue
            // 如果兄弟有 closeMenu 函数，就调用它
            if (typeof sibling.closeMenu === "function") {
                sibling.closeMenu()
            }
        }
    }

    onClicked: (event) => {
        if (event.button === Qt.LeftButton) {
            modelData.activate();
            trayMenu.visible = false;
        } else if (event.button === Qt.RightButton) {
            // 如果当前是关的，准备打开 -> 先关闭别人
            if (!trayMenu.visible) {
                closeOtherMenus()
                trayMenu.visible = true
            } else {
                // 如果当前是开的 -> 直接关闭
                trayMenu.visible = false
            }
        }
    }

    TrayMenu {
        id: trayMenu
        
        rootMenuHandle: root.modelData.menu
        trayName: root.modelData.tooltipTitle || root.modelData.id || "Menu"
        
        anchor.item: root
        // 确保位置正确
        anchor.rect.y: (root.mapToItem(null, 0, 0).y > 500) ? -trayMenu.implicitHeight - 5 : root.height + 5
        anchor.rect.x: 0
    }

    Image {
        id: content
        anchors.fill: parent
        anchors.margins: 2
        
        source: {
            const raw = root.modelData.icon;
            if (raw.indexOf("spotify") !== -1) {
                return "image://icon/spotify";
            }
            return raw;
        }
        
        cache: true
        asynchronous: true
        fillMode: Image.PreserveAspectFit
    }
}
