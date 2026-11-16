pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property int cardW: 320
    readonly property int cardH: 145
    readonly property int blockW: 90
    readonly property int blockH: 44

    readonly property string radarrUrl: (Plasmoid.configuration.radarrUrl || "http://localhost:7878").replace(/\/+$/, "")
    readonly property string clickUrl: (Plasmoid.configuration.clickUrl && Plasmoid.configuration.clickUrl.trim() !== "")
                                       ? Plasmoid.configuration.clickUrl.trim()
                                       : radarrUrl
    readonly property string radarrKey: (Plasmoid.configuration.radarrKey || "").trim()
    readonly property string jellyfinUrl: (Plasmoid.configuration.jellyfinUrl || "http://localhost:8096").replace(/\/+$/, "")
    readonly property string jellyfinToken: (Plasmoid.configuration.jellyfinToken || "").trim()
    readonly property string titleText: Plasmoid.configuration.titleText || "Radarr"
    readonly property string subtitleText: Plasmoid.configuration.subtitleText || "Gerenciamento de Filmes"

    property string missingCount: "-"
    property string queueCount: "-"
    property string moviesCount: "-"
    property bool online: false

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    FontLoader { source: Qt.resolvedUrl("../fonts/FiraSans-Regular.otf") }
    FontLoader { source: Qt.resolvedUrl("../fonts/FiraSans-Medium.otf") }
    FontLoader { source: Qt.resolvedUrl("../fonts/FiraSans-SemiBold.otf") }
    FontLoader { source: Qt.resolvedUrl("../fonts/FiraSans-Bold.otf") }

    implicitWidth: cardW
    implicitHeight: cardH
    Layout.preferredWidth: cardW
    Layout.preferredHeight: cardH
    Layout.minimumWidth: 160
    Layout.minimumHeight: 72

    onRadarrUrlChanged: fetchAll()
    onRadarrKeyChanged: fetchAll()
    onJellyfinUrlChanged: fetchAll()
    onJellyfinTokenChanged: fetchAll()

    function fetchAll() {
        if (!radarrKey) {
            root.online = false;
            return;
        }

        var xhrMissing = new XMLHttpRequest();
        xhrMissing.open("GET", radarrUrl + "/api/v3/wanted/missing?apiKey=" + radarrKey + "&pageSize=1", true);
        xhrMissing.onreadystatechange = function() {
            if (xhrMissing.readyState === XMLHttpRequest.DONE) {
                if (xhrMissing.status === 200) {
                    try {
                        var data = JSON.parse(xhrMissing.responseText);
                        root.missingCount = (data.totalRecords !== undefined) ? String(data.totalRecords) : "-";
                        root.online = true;
                    } catch (e) {}
                } else {
                    root.online = false;
                }
            }
        };
        xhrMissing.send();

        var xhrQueue = new XMLHttpRequest();
        xhrQueue.open("GET", radarrUrl + "/api/v3/queue?apiKey=" + radarrKey, true);
        xhrQueue.onreadystatechange = function() {
            if (xhrQueue.readyState === XMLHttpRequest.DONE && xhrQueue.status === 200) {
                try {
                    var data = JSON.parse(xhrQueue.responseText);
                    root.queueCount = (data.totalRecords !== undefined) ? String(data.totalRecords) : "-";
                } catch (e) {}
            }
        };
        xhrQueue.send();

        if (jellyfinToken !== "") {
            var xhrMovies = new XMLHttpRequest();
            xhrMovies.open("GET", jellyfinUrl + "/Items/Counts", true);
            xhrMovies.setRequestHeader("Authorization", 'MediaBrowser Token="' + jellyfinToken + '"');
            xhrMovies.onreadystatechange = function() {
                if (xhrMovies.readyState === XMLHttpRequest.DONE && xhrMovies.status === 200) {
                    try {
                        var data = JSON.parse(xhrMovies.responseText);
                        root.moviesCount = (data.MovieCount !== undefined) ? String(data.MovieCount) : "-";
                    } catch (e) {}
                }
            };
            xhrMovies.send();
        } else {
            var xhrRadarrMovies = new XMLHttpRequest();
            xhrRadarrMovies.open("GET", radarrUrl + "/api/v3/movie?apiKey=" + radarrKey, true);
            xhrRadarrMovies.onreadystatechange = function() {
                if (xhrRadarrMovies.readyState === XMLHttpRequest.DONE && xhrRadarrMovies.status === 200) {
                    try {
                        var list = JSON.parse(xhrRadarrMovies.responseText);
                        if (Array.isArray(list)) {
                            var count = 0;
                            for (var i = 0; i < list.length; i++) {
                                if (list[i] && list[i].hasFile) count++;
                            }
                            root.moviesCount = String(count > 0 ? count : list.length);
                        }
                    } catch (e) {}
                }
            };
            xhrRadarrMovies.send();
        }
    }

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshIntervalSec || 30) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchAll()
    }

    fullRepresentation: Item {
        anchors.fill: parent
        implicitWidth: root.cardW
        implicitHeight: root.cardH

        Item {
            id: cardContainer
            width: root.cardW
            height: root.cardH
            anchors.centerIn: parent
            scale: Math.min(parent.width / root.cardW, parent.height / root.cardH)

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Qt.rgba(13/255, 17/255, 28/255, 215/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 20/255)
            }

            Image {
                x: 18
                y: 16
                width: 34
                height: 34
                source: Qt.resolvedUrl("../icons/radarr.png")
                smooth: true
                mipmap: true
            }

            Rectangle {
                x: 298
                y: 18
                width: 8
                height: 8
                radius: 4
                color: root.online ? Qt.rgba(34/255, 197/255, 94/255, 1) : Qt.rgba(239/255, 68/255, 68/255, 1)
            }

            Text {
                x: 60
                y: 14
                text: root.titleText
                font.family: "Fira Sans"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: Qt.rgba(248/255, 250/255, 252/255, 1)
                renderType: Text.NativeRendering
            }

            Text {
                x: 60
                y: 35
                text: root.subtitleText
                font.family: "Fira Sans"
                font.pixelSize: 11
                color: Qt.rgba(203/255, 213/255, 225/255, 150/255)
                renderType: Text.NativeRendering
            }

            // BLOCO 1: FALTANDO
            Rectangle {
                x: 18
                y: 68
                width: root.blockW
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    text: root.missingCount
                    font.family: "Fira Sans"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 26
                    text: "FALTANDO"
                    font.family: "Fira Sans"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // BLOCO 2: NA FILA
            Rectangle {
                x: 115
                y: 68
                width: root.blockW
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    text: root.queueCount
                    font.family: "Fira Sans"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 26
                    text: "NA FILA"
                    font.family: "Fira Sans"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // BLOCO 3: FILMES
            Rectangle {
                x: 212
                y: 68
                width: root.blockW
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    text: root.moviesCount
                    font.family: "Fira Sans"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 26
                    text: "FILMES"
                    font.family: "Fira Sans"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally(root.clickUrl)
            }
        }
    }
}
