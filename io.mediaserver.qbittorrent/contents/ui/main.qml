pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property int cardW: 320
    readonly property int cardH: 145
    readonly property int blockH: 50

    readonly property string qbitUrl: (Plasmoid.configuration.qbitUrl || "http://localhost:8080").replace(/\/+$/, "")
    readonly property string clickUrl: (Plasmoid.configuration.clickUrl && Plasmoid.configuration.clickUrl.trim() !== "")
                                       ? Plasmoid.configuration.clickUrl.trim()
                                       : qbitUrl
    readonly property string qbitUsername: (Plasmoid.configuration.qbitUsername || "admin").trim()
    readonly property string qbitPassword: Plasmoid.configuration.qbitPassword || ""
    readonly property string titleText: Plasmoid.configuration.titleText || "qBittorrent"
    readonly property string subtitleText: Plasmoid.configuration.subtitleText || "Cliente de Transferência de Torrents"

    property string leechCount: "0"
    property string downloadSpeed: "0 B/s"
    property string seedCount: "0"
    property string uploadSpeed: "0 B/s"
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

    onQbitUrlChanged: loginAndFetch()
    onQbitUsernameChanged: loginAndFetch()
    onQbitPasswordChanged: loginAndFetch()

    function formatSpeed(bytesPerSec) {
        var b = Number(bytesPerSec) || 0;
        if (b < 1024) {
            return Math.round(b) + " B/s";
        } else if (b < 1048576) {
            return (b / 1024).toFixed(1).replace(".", ",") + " KiB/s";
        } else if (b < 1073741824) {
            return (b / 1048576).toFixed(1).replace(".", ",") + " MiB/s";
        } else {
            return (b / 1073741824).toFixed(2).replace(".", ",") + " GiB/s";
        }
    }

    function loginAndFetch() {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", qbitUrl + "/api/v2/auth/login", true);
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    fetchMainData(false);
                } else {
                    root.online = false;
                }
            }
        };
        var body = "username=" + encodeURIComponent(qbitUsername) + "&password=" + encodeURIComponent(qbitPassword);
        xhr.send(body);
    }

    function fetchMainData(allowRetryLogin) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", qbitUrl + "/api/v2/sync/maindata", true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        var st = data.server_state || {};
                        root.downloadSpeed = formatSpeed(st.dl_info_speed || 0);
                        root.uploadSpeed = formatSpeed(st.up_info_speed || 0);

                        var torrents = data.torrents || {};
                        var leech = 0;
                        var seed = 0;
                        for (var hash in torrents) {
                            if (Object.prototype.hasOwnProperty.call(torrents, hash)) {
                                var t = torrents[hash];
                                if (t.progress === 1 || t.amount_left === 0) {
                                    seed++;
                                } else {
                                    leech++;
                                }
                            }
                        }
                        root.leechCount = String(leech);
                        root.seedCount = String(seed);
                        root.online = true;
                    } catch (e) {}
                } else if (xhr.status === 403 && allowRetryLogin) {
                    loginAndFetch();
                } else {
                    root.online = false;
                }
            }
        };
        xhr.send();
    }

    Timer {
        interval: Math.max(1, Plasmoid.configuration.refreshIntervalSec || 3) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchMainData(true)
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

            // [MeterBackground]
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Qt.rgba(13/255, 17/255, 28/255, 215/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 20/255)
            }

            // [MeterIcon]
            Image {
                x: 18
                y: 16
                width: 34
                height: 34
                source: Qt.resolvedUrl("../icons/qbittorrent.png")
                smooth: true
                mipmap: true
            }

            // [MeterStatusDot]
            Rectangle {
                x: 298
                y: 18
                width: 8
                height: 8
                radius: 4
                color: root.online ? Qt.rgba(34/255, 197/255, 94/255, 1) : Qt.rgba(239/255, 68/255, 68/255, 1)
            }

            // [MeterTitle]
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

            // [MeterDescription]
            Text {
                x: 60
                y: 35
                text: root.subtitleText
                font.family: "Fira Sans"
                font.pixelSize: 11
                color: Qt.rgba(203/255, 213/255, 225/255, 150/255)
                renderType: Text.NativeRendering
            }

            // BLOCO 1: LEECH
            Rectangle {
                x: 18
                y: 66
                width: 66
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    text: root.leechCount
                    font.family: "Fira Sans"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28
                    text: "LEECH"
                    font.family: "Fira Sans"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // BLOCO 2: DOWNLOAD
            Rectangle {
                x: 90
                y: 66
                width: 67
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    width: 63
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.downloadSpeed
                    font.family: "Fira Sans"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28
                    text: "DOWNLOAD"
                    font.family: "Fira Sans"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // BLOCO 3: SEED
            Rectangle {
                x: 163
                y: 66
                width: 67
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    text: root.seedCount
                    font.family: "Fira Sans"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28
                    text: "SEED"
                    font.family: "Fira Sans"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // BLOCO 4: UPLOAD
            Rectangle {
                x: 236
                y: 66
                width: 66
                height: root.blockH
                radius: 8
                color: Qt.rgba(1, 1, 1, 9/255)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 14/255)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    width: 62
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.uploadSpeed
                    font.family: "Fira Sans"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28
                    text: "UPLOAD"
                    font.family: "Fira Sans"
                    font.pixelSize: 8
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
