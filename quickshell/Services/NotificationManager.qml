import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    property alias model: notifModel
    property bool hasNotifs: notifModel.count > 0

    ListModel { id: notifModel }

    NotificationServer {
        id: server
        
        onNotification: (n) => {
            // 1. 过滤播放器
            if (n.desktopEntry === "spotify" || n.desktopEntry.includes("player")) return;

            // 2. 队列管理
            if (notifModel.count >= 2) notifModel.remove(0);

            // ====================================================
            // 3. 【智能图标策略】
            // ====================================================
            
            // 定义“强制使用图标”的黑名单
            // 这些 App 的头像往往显示效果不好，我们强制它们显示 App Logo
            const forceIconApps = [
                "qq", "com.tencent.qq", "linuxqq",
                "wechat", "com.tencent.wechat", "electronic-wechat",
                "telegram", "org.telegram.desktop", "telegram-desktop"
            ];
            
            // 判断当前通知是否来自黑名单 App
            const shouldForceIcon = forceIconApps.includes(n.desktopEntry.toLowerCase());

            let finalImage = "";

            // --- 分支 A: 允许显示图片 (截图工具走这里) ---
            // 条件：不在黑名单里，且通知真的带了图片路径
            if (!shouldForceIcon && n.image && (n.image.startsWith("/") || n.image.startsWith("file://"))) {
                 finalImage = n.image.startsWith("/") ? "file://" + n.image : n.image;
            }
            // --- 分支 B: 强制/兜底显示 App 图标 (QQ走这里) ---
            else {
                // 依次尝试获取图标名
                let iconName = n.appIcon || n.desktopEntry || n.icon || "";
                
                if (iconName !== "") {
                    if (iconName.startsWith("/") || iconName.startsWith("file://")) {
                        finalImage = iconName.startsWith("/") ? "file://" + iconName : iconName;
                    } else {
                        // 标准系统图标
                        finalImage = "icon:" + iconName;
                    }
                }
            }

            // 4. 添加到模型
            notifModel.append({
                "id": n.id,
                "summary": n.summary,
                "body": n.body,
                "imagePath": finalImage
            });

            // 5. 计时器
            dismissTimer.restart();
        }
    }

    Timer {
        id: dismissTimer
        interval: 3000
        repeat: false
        onTriggered: notifModel.clear()
    }

    function remove(index) {
        if (index >= 0 && index < notifModel.count) notifModel.remove(index);
        if (notifModel.count > 0) dismissTimer.restart();
        else dismissTimer.stop();
    }
}
