import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Components
import qs.config
import QtQuick.Effects

Item {
    id: root

    // --- 属性定义 ---
    required property var player
    readonly property bool isActive: root.visible && root.player

    property string title: (isActive && player.trackTitle) ? player.trackTitle : "No Media"
    property string artist: (isActive && player.trackArtist) ? player.trackArtist : ""
    property string playerName: isActive ? (player.identity || player.busName || "") : ""
    property double progress: (isActive && player.length > 0) ? (player.position / player.length) : 0
    property string displayArtUrl: ""
    property string lastTrackId: ""

    // 歌词相关
    property var lyricsModel: []
    property int currentLineIndex: 0
    property string currentLyricText: ""

    // --- 封面防抖触发 ---
    onPlayerChanged: artDebounceTimer.restart()
    onTitleChanged: {
        artDebounceTimer.restart()
        lyricsDebounceTimer.restart()
    }
    onArtistChanged: artDebounceTimer.restart()

    Connections {
        target: player
        ignoreUnknownSignals: true
        function onTrackArtUrlChanged() {
            if (player && player.trackArtUrl && player.trackArtUrl !== "") {
                root.displayArtUrl = player.trackArtUrl;
            } else {
                artDebounceTimer.restart();
            }
        }
    }

    Timer {
        id: artDebounceTimer
        interval: 150
        repeat: false
        onTriggered: updateArtSource()
    }

    function updateArtSource() {
        if (root.title === "No Media" && root.artist === "") return;

        let currentId = root.title + root.artist;
        if (currentId === lastTrackId && root.displayArtUrl !== "") return;

        lastTrackId = currentId;
        displayArtUrl = "";

        // 优先用播放器自带 artUrl，最快
        if (player && player.trackArtUrl && player.trackArtUrl !== "") {
            displayArtUrl = player.trackArtUrl;
            return;
        }

        // 没有才走脚本
        coverFetcher.fullOutput = "";
        if (coverFetcher.running) coverFetcher.running = false;
        coverFetcher.running = true;
    }

    // --- 封面下载进程 ---
    Process {
        id: coverFetcher
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/cover_fetcher.py", root.title, root.artist]

        property string fullOutput: ""

        stdout: SplitParser {
            onRead: (data) => { coverFetcher.fullOutput += data; }
        }

        onExited: (exitCode) => {
            if (exitCode === 0) {
                let path = coverFetcher.fullOutput.trim();
                if (path !== "" && path.startsWith("/")) {
                    root.displayArtUrl = "file://" + path;
                    console.log("[DEBUG] Cover localized:", root.displayArtUrl);
                } else {
                    root.displayArtUrl = "";
                }
            }
        }
    }

    // --- 歌词获取进程 ---
    Process {
        id: lyricsFetcher
        command: ["python3", Quickshell.shellDir + "/scripts/lyrics_fetcher.py", root.title, root.artist, root.playerName]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var json = JSON.parse(data)
                    if (json.length > 0) {
                        root.lyricsModel = json;
                        root.currentLineIndex = 0;
                    } else {
                        root.lyricsModel = [{time: 0, text: "暂无歌词"}]
                    }
                } catch (e) {
                    root.lyricsModel = [{time: 0, text: ""}]
                }
            }
        }
    }

    Timer {
        id: lyricsDebounceTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (root.title !== "No Media") {
                root.lyricsModel = []
                root.currentLineIndex = 0
                root.currentLyricText = ""
                if (lyricsFetcher.running) lyricsFetcher.running = false
                    lyricsFetcher.running = true
            }
        }
    }

    // --- 歌词同步 ---
    Timer {
        interval: 100
        running: root.isActive && root.lyricsModel.length > 1
        repeat: true
        onTriggered: {
            if (!root.player) return
                var rawPos = root.player.position
                var currentSec = (rawPos > 100000) ? (rawPos / 1000000) : rawPos

                var activeIdx = -1
                for (var i = 0; i < root.lyricsModel.length; i++) {
                    if (root.lyricsModel[i].time <= (currentSec + 0.5)) activeIdx = i; else break
                }

                if (activeIdx !== -1 && activeIdx !== root.currentLineIndex) {
                    root.currentLineIndex = activeIdx
                    root.currentLyricText = root.lyricsModel[activeIdx].text || ""
                }
        }
    }

    // --- UI 布局 ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            spacing: 15

            // 封面图容器（保留原有样式）
            Rectangle {
                id: coverContainer
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: 12
                color: "#1a1a1a"
                clip: false

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: coverContainer.width
                        height: coverContainer.height
                        radius: coverContainer.radius
                    }
                }

                Image {
                    id: coverImg
                    anchors.fill: parent
                    source: root.displayArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(128, 128)

                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 250 }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "♫"
                    color: "#333"
                    font.pixelSize: 24
                    visible: coverImg.status !== Image.Ready
                }
            }

            // 文字信息
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.title
                    color: "white"
                    font.bold: true; font.pixelSize: 16
                    elide: Text.ElideRight; Layout.fillWidth: true
                }

                Text {
                    text: root.artist
                    color: "#888"; font.pixelSize: 13
                    elide: Text.ElideRight; Layout.fillWidth: true
                }

                // 歌词显示
                Text {
                    id: lyricLine
                    Layout.fillWidth: true
                    text: root.currentLyricText
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.italic: true
                    elide: Text.ElideRight
                    visible: root.currentLyricText !== ""

                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation { target: lyricLine; property: "opacity"; to: 0; duration: 120 }
                            PropertyAction {}
                            NumberAnimation { target: lyricLine; property: "opacity"; to: 1; duration: 120 }
                        }
                    }
                }
            }
        }

        // 进度条
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            Rectangle {
                id: barBg
                anchors.fill: parent; color: "#333"; radius: 3
                Rectangle {
                    height: parent.height; radius: 3; color: "white"
                    width: seekMa.pressed ?
                    Math.min(Math.max(0, seekMa.mouseX), barBg.width) :
                    (root.progress * barBg.width)

                    Behavior on width {
                        enabled: !seekMa.pressed
                        SmoothedAnimation { velocity: 200 }
                    }
                }
                MouseArea {
                    id: seekMa
                    anchors.fill: parent; anchors.margins: -10
                    onReleased: (mouse) => {
                        if (player && player.length > 0) {
                            let p = Math.min(Math.max(0, mouse.x / barBg.width), 1);
                            player.position = p * player.length;
                        }
                    }
                }
            }
        }

        // 控制按钮
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 40

            Text {
                text: "⏮"; color: "white"; font.pixelSize: 25
                MouseArea { anchors.fill: parent; onClicked: player.previous() }
            }
            Text {
                text: (player && player.isPlaying) ? "⏸" : "▶"
                color: "white"; font.pixelSize: 28
                MouseArea { anchors.fill: parent; onClicked: player.togglePlaying() }
            }
            Text {
                text: "⏭"; color: "white"; font.pixelSize: 25
                MouseArea { anchors.fill: parent; onClicked: player.next() }
            }
        }
    }
}
