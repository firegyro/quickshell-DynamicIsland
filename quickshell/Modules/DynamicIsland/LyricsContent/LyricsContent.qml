import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import qs.config

Item {
    id: root

    required property var player
    property bool active: false
    property var lyricsModel: []
    property int currentLineIndex: 0

    property string trackTitle: player ? player.trackTitle : ""
    property string trackArtist: player ? player.trackArtist : ""
    property string playerName: player ? (player.identity || player.busName || "") : ""
    property string artUrl: player ? (player.trackArtUrl || "") : ""

    property bool isPlaying: player && player.playbackStatus === Mpris.Playing

    property string displayArtUrl: ""
    property string lastTrackId: ""
    property string currentLoadedTitle: ""

    // ================= 1. 触发时机 =================
    onPlayerChanged: artDebounceTimer.restart()

    onTrackTitleChanged: {
        triggerReload()
        artDebounceTimer.restart()
    }

    onTrackArtistChanged: artDebounceTimer.restart()

    onArtUrlChanged: {
        if (root.artUrl !== "") {
            displayArtUrl = root.artUrl
        }
    }

    onActiveChanged: {
        if (active && root.trackTitle !== root.currentLoadedTitle) triggerReload()
            if (active) artDebounceTimer.restart()
    }

    // ================= 2. 封面防抖 Timer =================
    Timer {
        id: artDebounceTimer
        interval: 150
        repeat: false
        onTriggered: updateArtSource()
    }

    // ================= 3. 封面抓取 =================
    function updateArtSource() {
        if (root.trackTitle === "" && root.trackArtist === "") return;

        let currentId = root.trackTitle + root.trackArtist;
        if (currentId === lastTrackId && root.displayArtUrl !== "") return;

        lastTrackId = currentId;
        displayArtUrl = "";

        if (root.artUrl !== "") {
            displayArtUrl = root.artUrl;
            return;
        }

        coverFetcher.fullOutput = "";
        if (coverFetcher.running) coverFetcher.running = false;
        coverFetcher.running = true;
    }

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

    Process {
        id: coverFetcher
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/cover_fetcher.py", root.trackTitle, root.trackArtist]

        property string fullOutput: ""

        stdout: SplitParser {
            onRead: (data) => {
                coverFetcher.fullOutput += data;
            }
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

    // ================= 4. 歌词获取 =================
    Process {
        id: lyricsFetcher
        command: ["python3", Quickshell.shellDir + "/scripts/lyrics_fetcher.py", root.trackTitle, root.trackArtist, root.playerName]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var json = JSON.parse(data)
                    if (json.length > 0) {
                        root.lyricsModel = json;
                        root.currentLineIndex = 0;
                        root.currentLoadedTitle = root.trackTitle
                    } else {
                        root.lyricsModel = [{time: 0, text: "暂无歌词"}]
                    }
                } catch (e) {
                    root.lyricsModel = [{time: 0, text: "歌词错误"}]
                }
            }
        }
    }

    function triggerReload() {
        if (!root.active) return
            if (lyricsFetcher.running) lyricsFetcher.running = false
                debounceTimer.restart()
    }

    Timer {
        id: debounceTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (root.trackTitle !== "") {
                root.lyricsModel = []
                root.currentLineIndex = 0
                lyricsFetcher.running = true
            }
        }
    }

    // ================= 5. 歌词同步 =================
    Timer {
        interval: 100
        running: root.active && root.lyricsModel.length > 1 && root.player
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
                }
        }
    }

    // ================= 6. 界面层 =================
    Item {
        anchors.fill: parent
        clip: true

        // 旋转圆形专辑封面
        Item {
            id: albumArtWrapper
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            visible: root.displayArtUrl !== ""

            Rectangle {
                id: rotatingContainer
                anchors.fill: parent
                radius: width / 2
                color: "transparent"

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 8000
                    loops: Animation.Infinite
                    running: root.isPlaying
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: rotatingContainer.width
                        height: rotatingContainer.height
                        radius: rotatingContainer.radius
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
            }
        }

        // 封面不可用时的音符 fallback
        Text {
            visible: root.displayArtUrl === ""
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf001"
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 14
            color: "#80ffffff"
        }

        // 歌词列表
        ListView {
            id: lyricsView
            anchors.left: albumArtWrapper.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            interactive: false
            model: root.lyricsModel
            currentIndex: root.currentLineIndex

            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 42
            highlightMoveDuration: 400

            delegate: Item {
                width: ListView.view.width
                height: 42
                property bool isCurrent: ListView.isCurrentItem

                Text {
                    anchors.centerIn: parent
                    text: modelData.text
                    color: isCurrent ? "white" : "transparent"
                    font.pixelSize: 14; font.bold: true
                    elide: Text.ElideRight; width: parent.width; horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
}
