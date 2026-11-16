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

    readonly property string prowlarrUrl: (Plasmoid.configuration.prowlarrUrl || "http://localhost:9696").replace(/\/+$/, "")
    readonly property string clickUrl: (Plasmoid.configuration.clickUrl && Plasmoid.configuration.clickUrl.trim() !== "")
                                       ? Plasmoid.configuration.clickUrl.trim()
                                       : prowlarrUrl
    readonly property string prowlarrKey: (Plasmoid.configuration.prowlarrKey || "").trim()
    readonly property string titleText: Plasmoid.configuration.titleText || "Prowlarr"
    readonly property string subtitleText: Plasmoid.configuration.subtitleText || "Gerenciamento Central de Indexadores"

    property string grabsCount: "-"
    property string queriesCount: "-"
    property string failedGrabsCount: "-"
    property string failedQueriesCount: "-"
    property bool online: false

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    implicitWidth: cardW
    implicitHeight: cardH
    Layout.preferredWidth: cardW
    Layout.preferredHeight: cardH
    Layout.minimumWidth: 160
    Layout.minimumHeight: 72

    onProwlarrUrlChanged: fetchStats()
    onProwlarrKeyChanged: fetchStats()

    function fetchStats() {
        if (!prowlarrKey) {
            root.online = false;
            return;
        }

        var xhr = new XMLHttpRequest();
        xhr.open("GET", prowlarrUrl + "/api/v1/indexerstats?apikey=" + prowlarrKey, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        var indexers = data.indexers || [];
                        var grabs = 0;
                        var queries = 0;
                        var failedGrabs = 0;
                        var failedQueries = 0;
                        for (var i = 0; i < indexers.length; i++) {
                            var idx = indexers[i];
                            grabs += (idx.numberOfGrabs || 0);
                            queries += (idx.numberOfQueries || 0);
                            failedGrabs += (idx.numberOfFailedGrabs || 0);
                            failedQueries += (idx.numberOfFailedQueries || 0);
                        }
                        root.grabsCount = String(grabs);
                        root.queriesCount = String(queries);
                        root.failedGrabsCount = String(failedGrabs);
                        root.failedQueriesCount = String(failedQueries);
                        root.online = true;
                    } catch (e) {}
                } else {
                    root.online = false;
                }
            }
        };
        xhr.send();
    }

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshIntervalSec || 30) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchStats()
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
                source: Qt.resolvedUrl("../icons/prowlarr.png")
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

            // BLOCO 1: BUSCAS
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
                    y: 5
                    text: root.grabsCount
                    font.family: "Fira Sans"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28
                    text: "BUSCAS"
                    font.family: "Fira Sans"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // BLOCO 2: CONSULTAS
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
                    y: 5
                    text: root.queriesCount
                    font.family: "Fira Sans"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28
                    text: "CONSULTAS"
                    font.family: "Fira Sans"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // BLOCO 3: BUSCAS SEM ÊXITO
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
                    y: 4
                    text: root.failedGrabsCount
                    font.family: "Fira Sans"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 23
                    text: "BUSCAS SEM\nÊXITO"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 0.9
                    font.family: "Fira Sans"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Qt.rgba(203/255, 213/255, 225/255, 130/255)
                    renderType: Text.NativeRendering
                }
            }

            // BLOCO 4: CONSULTAS FALHAS
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
                    y: 4
                    text: root.failedQueriesCount
                    font.family: "Fira Sans"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Qt.rgba(248/255, 250/255, 252/255, 1)
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 23
                    text: "CONSULTAS\nFALHAS"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 0.9
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
