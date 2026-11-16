pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property int cardW: 320
    readonly property int cardH: 175
    readonly property int blockW: 90
    readonly property int blockH: 44

    readonly property string apiUrl: (Plasmoid.configuration.apiUrl || "http://localhost:8096").replace(/\/+$/, "")
    readonly property string clickUrl: (Plasmoid.configuration.clickUrl && Plasmoid.configuration.clickUrl.trim() !== "")
                                       ? Plasmoid.configuration.clickUrl.trim()
                                       : apiUrl
    readonly property int clickActionMode: Plasmoid.configuration.clickActionMode || 0
    readonly property string clientCommand: (Plasmoid.configuration.clientCommand || "jellium-desktop").trim()
    readonly property string apiToken: (Plasmoid.configuration.apiToken || "").trim()
    readonly property string titleText: Plasmoid.configuration.titleText || "Jellyfin"
    readonly property string subtitleText: Plasmoid.configuration.subtitleText || "Servidor de Streaming"

    property string movieCount: "-"
    property string seriesCount: "-"
    property string episodeCount: "-"
    property bool online: false

    property bool isPlaying: false
    property string npHeader: "TOCANDO:"
    property string npTitle: "-"
    property string npTime: "00:00 / 00:00"
    property int npBarW: 4

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
    Layout.minimumHeight: 88

    onApiUrlChanged: { fetchCounts(); fetchSessions(); }
    onApiTokenChanged: { fetchCounts(); fetchSessions(); }

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    P5Support.DataSource {
        id: appLauncher
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source);
        }
    }

    function focusExistingClientWindow() {
        var customCmd = root.clientCommand.toLowerCase();
        var tokens = [];

        if (customCmd !== "") {
            var parts = customCmd.split(/\s+/);
            var lastPart = parts[parts.length - 1];
            // Remove path prefix if any (e.g. /usr/bin/jellium-desktop -> jellium-desktop)
            var baseBin = lastPart.split("/").pop();
            if (baseBin) {
                tokens.push(baseBin);
                var firstWord = baseBin.split("-")[0];
                if (firstWord && firstWord.length >= 4) {
                    tokens.push(firstWord);
                }
            }
        }

        if (root.clickActionMode === 0) {
            tokens.push("jellium");
            tokens.push("jellyfinmediaplayer");
            tokens.push("jellyfin-media-player");
            tokens.push("delfin");
            tokens.push("feishin");
        }

        for (var i = 0; i < tasksModel.count; i++) {
            var idx = tasksModel.makeModelIndex(i);
            var appId = String(tasksModel.data(idx, TaskManager.AbstractTasksModel.AppId) || "").toLowerCase();
            var appName = String(tasksModel.data(idx, TaskManager.AbstractTasksModel.AppName) || "").toLowerCase();
            var launcher = String(tasksModel.data(idx, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon) || "").toLowerCase();
            var title = String(tasksModel.data(idx, Qt.DisplayRole) || "").toLowerCase();
            var combined = appId + " " + appName + " " + launcher + " " + title;

            for (var t = 0; t < tokens.length; t++) {
                var tok = tokens[t];
                if (tok && combined.indexOf(tok) !== -1) {
                    tasksModel.requestActivate(idx);
                    return true;
                }
            }
        }
        return false;
    }

    function openJellyfinClient() {
        if (root.clickActionMode === 2) {
            Qt.openUrlExternally(root.clickUrl);
            return;
        }

        // 1. Se o cliente já estiver aberto no sistema, traz a janela para o primeiro plano via protocolo nativo do KDE/Wayland
        if (focusExistingClientWindow()) {
            return;
        }

        // 2. Caso não esteja aberto, inicia o cliente configurado
        var customCmd = root.clientCommand;
        if (root.clickActionMode === 1 && customCmd !== "") {
            appLauncher.connectSource("nohup " + customCmd + " >/dev/null 2>&1 &");
            return;
        }

        // Modo 0: Tenta o comando configurado primeiro; se não existir no sistema, auto-detecta clientes conhecidos ou abre a URL no navegador
        var fallbackUrl = root.clickUrl.replace(/"/g, "");
        var cmdBin = customCmd.split(" ")[0];
        var shellCmd = 'if [ -n "' + cmdBin + '" ] && command -v "' + cmdBin + '" >/dev/null 2>&1; then ' +
                       'nohup ' + customCmd + ' >/dev/null 2>&1 & ' +
                       'elif command -v jellium-desktop >/dev/null 2>&1; then nohup jellium-desktop >/dev/null 2>&1 & ' +
                       'elif command -v jellyfinmediaplayer >/dev/null 2>&1; then nohup jellyfinmediaplayer >/dev/null 2>&1 & ' +
                       'elif command -v delfin >/dev/null 2>&1; then nohup delfin >/dev/null 2>&1 & ' +
                       'elif command -v flatpak >/dev/null 2>&1 && flatpak info net.nullsum.JelliumDesktop >/dev/null 2>&1; then nohup flatpak run net.nullsum.JelliumDesktop >/dev/null 2>&1 & ' +
                       'elif command -v flatpak >/dev/null 2>&1 && flatpak info com.github.iwalton3.jellyfin-media-player >/dev/null 2>&1; then nohup flatpak run com.github.iwalton3.jellyfin-media-player >/dev/null 2>&1 & ' +
                       'else xdg-open "' + fallbackUrl + '" >/dev/null 2>&1 & fi';
        appLauncher.connectSource(shellCmd);
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Abrir Cliente Desktop (" + (root.clientCommand || "Auto") + ")"
            icon.name: "media-playback-start"
            onTriggered: root.openJellyfinClient()
        },
        PlasmaCore.Action {
            text: "Abrir Jellyfin Web no Navegador"
            icon.name: "internet-web-browser"
            onTriggered: Qt.openUrlExternally(root.clickUrl)
        }
    ]

    function formatSec(sec) {
        if (!sec || sec <= 0) return "00:00";
        var h = Math.floor(sec / 3600);
        var m = Math.floor((sec % 3600) / 60);
        var s = Math.floor(sec % 60);
        var mm = (m < 10 ? "0" : "") + m;
        var ss = (s < 10 ? "0" : "") + s;
        if (h > 0) {
            return h + ":" + mm + ":" + ss;
        }
        return mm + ":" + ss;
    }

    function fetchCounts() {
        if (!apiToken) {
            root.online = false;
            return;
        }
        var xhr = new XMLHttpRequest();
        xhr.open("GET", apiUrl + "/Items/Counts", true);
        xhr.setRequestHeader("Authorization", 'MediaBrowser Token="' + apiToken + '"');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        root.movieCount = (data.MovieCount !== undefined) ? String(data.MovieCount) : "-";
                        root.seriesCount = (data.SeriesCount !== undefined) ? String(data.SeriesCount) : "-";
                        root.episodeCount = (data.EpisodeCount !== undefined) ? String(data.EpisodeCount) : "-";
                        root.online = true;
                    } catch (e) {}
                } else {
                    root.online = false;
                }
            }
        };
        xhr.send();
    }

    function fetchSessions() {
        if (!apiToken) {
            root.online = false;
            root.isPlaying = false;
            return;
        }
        var xhr = new XMLHttpRequest();
        xhr.open("GET", apiUrl + "/Sessions", true);
        xhr.setRequestHeader("Authorization", 'MediaBrowser Token="' + apiToken + '"');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    root.online = true;
                    try {
                        var sessions = JSON.parse(xhr.responseText);
                        var activeSession = null;
                        for (var i = 0; i < sessions.length; i++) {
                            if (sessions[i] && sessions[i].NowPlayingItem) {
                                activeSession = sessions[i];
                                break;
                            }
                        }
                        if (!activeSession) {
                            root.isPlaying = false;
                            return;
                        }
                        var item = activeSession.NowPlayingItem;
                        var playState = activeSession.PlayState || {};
                        var name = item.Name || "Reproduzindo";
                        var seriesName = item.SeriesName || "";
                        var seasonIndex = item.ParentIndexNumber;
                        var epIndex = item.IndexNumber;
                        var runtimeTicks = item.RunTimeTicks || 0;
                        var positionTicks = playState.PositionTicks || 0;
                        var isPaused = !!playState.IsPaused;
                        var userName = activeSession.UserName || "";

                        var title = name;
                        if (seriesName !== "") {
                            var s = (seasonIndex !== undefined && seasonIndex !== null) ? ("S" + seasonIndex) : "";
                            var e = (epIndex !== undefined && epIndex !== null) ? ("E" + epIndex) : "";
                            var epPart = "";
                            if (s !== "" && e !== "") epPart = s + ":" + e + " - ";
                            else if (s !== "") epPart = s + " - ";
                            else if (e !== "") epPart = e + " - ";
                            title = seriesName + " - " + epPart + name;
                        }
                        if (userName !== "") {
                            title = title + " (" + userName + ")";
                        }

                        var percent = 0;
                        if (runtimeTicks > 0) {
                            percent = Math.min(1, Math.max(0, positionTicks / runtimeTicks));
                        }
                        var barW = Math.max(4, Math.floor(percent * 284));
                        var posSec = Math.floor(positionTicks / 10000000);
                        var runSec = Math.floor(runtimeTicks / 10000000);

                        root.npHeader = isPaused ? "PAUSADO:" : "TOCANDO:";
                        root.npTitle = title;
                        root.npTime = formatSec(posSec) + " / " + formatSec(runSec);
                        root.npBarW = barW;
                        root.isPlaying = true;
                    } catch (e) {
                        root.isPlaying = false;
                    }
                } else {
                    root.online = false;
                }
            }
        };
        xhr.send();
    }

    Timer {
        interval: Math.max(5, Plasmoid.configuration.countsIntervalSec || 20) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchCounts()
    }

    Timer {
        interval: Math.max(1, Plasmoid.configuration.sessionsIntervalSec || 2) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchSessions()
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
                source: Qt.resolvedUrl("../icons/jellyfin.png")
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

            // FILMES
            Rectangle {
                x: 18
                y: 64
                width: root.blockW
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    text: root.movieCount
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

            // SÉRIES
            Rectangle {
                x: 115
                y: 64
                width: root.blockW
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    text: root.seriesCount
                    font.family: "Fira Sans"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 26
                    text: "SÉRIES"
                    font.family: "Fira Sans"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // EPISÓDIOS
            Rectangle {
                x: 212
                y: 64
                width: root.blockW
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    text: root.episodeCount
                    font.family: "Fira Sans"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 26
                    text: "EPISÓDIOS"
                    font.family: "Fira Sans"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // NOW PLAYING: IDLE GROUP
            Item {
                anchors.fill: parent
                visible: !root.isPlaying

                Rectangle {
                    x: 18
                    y: 120
                    width: 284
                    height: 1
                    color: Qt.rgba(1, 1, 1, 10/255)
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 132
                    text: root.apiToken ? "Nenhuma reprodução ativa" : "Configure a API Key nas opções do widget"
                    font.family: "Fira Sans"
                    font.pixelSize: 11
                    color: Qt.rgba(203/255, 213/255, 225/255, 150/255)
                    renderType: Text.NativeRendering
                }
            }

            // NOW PLAYING: PLAYING GROUP
            Item {
                anchors.fill: parent
                visible: root.isPlaying

                Rectangle {
                    x: 18
                    y: 120
                    width: 284
                    height: 1
                    color: Qt.rgba(1, 1, 1, 15/255)
                }

                Text {
                    x: 18
                    y: 128
                    text: root.npHeader
                    font.family: "Fira Sans"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Qt.rgba(129/255, 140/255, 248/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    x: 74
                    y: 127
                    width: 145
                    text: root.npTitle
                    elide: Text.ElideRight
                    font.family: "Fira Sans"
                    font.pixelSize: 11
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    y: 128
                    text: root.npTime
                    font.family: "Fira Sans"
                    font.pixelSize: 10
                    color: Qt.rgba(203/255, 213/255, 225/255, 150/255)
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    x: 18
                    y: 148
                    width: 284
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 15/255)
                }

                Rectangle {
                    x: 18
                    y: 148
                    width: root.npBarW
                    height: 6
                    radius: 3
                    color: Qt.rgba(129/255, 140/255, 248/255, 1)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openJellyfinClient()
            }
        }
    }
}
