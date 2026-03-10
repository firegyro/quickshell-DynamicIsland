import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

Item {
    id: root

    implicitWidth: mainRow.width
    implicitHeight: 40

    property var player

    property string title: (player && player.trackTitle) ? player.trackTitle : ""
    property string artist: (player && player.trackArtist) ? player.trackArtist : ""

    property string displayArtUrl: ""
    property string lastTrackId: ""

    property bool isPlaying: player && player.playbackStatus === Mpris.Playing

    onTitleChanged: artDebounceTimer.restart()
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
        if (root.title === "" && root.artist === "") return;

        let currentId = root.title + root.artist;
        if (currentId === lastTrackId && root.displayArtUrl !== "") return;

        lastTrackId = currentId;
        displayArtUrl = "";

        if (player && player.trackArtUrl && player.trackArtUrl !== "") {
            displayArtUrl = player.trackArtUrl;
            return;
        }

        coverFetcher.fullOutput = "";
        if (coverFetcher.running) coverFetcher.running = false;
        coverFetcher.running = true;
    }

    Process {
        id: coverFetcher
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/cover_fetcher.py", root.title, root.artist]

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

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 12

        // 1. 左侧：旋转专辑封面
        Item {
            id: albumArtWrapper
            width: 25; height: 25
            visible: root.displayArtUrl !== ""
            anchors.verticalCenter: parent.verticalCenter

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

        // 2. 中间：时间显示
        Text {
            id: timeTxt
            text: new Date().toLocaleString(Qt.locale("en_US"), "ddd dd MMM | hh:mm AP")
            color: "white"
            font.pixelSize: 14
            font.bold: true
            font.family: Sizes.fontFamily
            anchors.verticalCenter: parent.verticalCenter

            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: timeTxt.text = new Date().toLocaleString(Qt.locale("en_US"), "ddd dd MMM | hh:mm AP")
            }
        }


    }
}
