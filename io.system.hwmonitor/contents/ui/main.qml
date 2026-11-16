pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    // Layout Dimensions
    readonly property int cardW: 320
    readonly property int cardH: 428
    readonly property int padX: 18
    readonly property int rightX: 302
    readonly property int barW: 284

    // Auto-detected Hardware Metadata (with optional UI config overrides)
    property string autoCpuName: "CPU"
    property string autoCpuBadge: ""
    property real cpuMaxClockMHz: 4250
    readonly property real cpuMaxTemp: 95
    readonly property real cpuMaxPowerW: 90

    property string autoGpuName: "GPU"
    property string autoGpuBadge: ""
    readonly property real gpuMaxClockMHz: 3300
    readonly property real gpuMaxMemClockMHz: 2518
    readonly property real gpuMaxTemp: 95
    readonly property real gpuMaxHotSpot: 110
    readonly property real gpuMaxFanRPM: 3000
    property real gpuMaxPowerW: 180

    property string autoRamName: "Memória RAM"
    property string autoRamBadge: ""
    property string driverLabel: "[Ativo] Kernel Linux + Driver Nativo"

    readonly property string displayCpuName: (Plasmoid.configuration.customCpuName && Plasmoid.configuration.customCpuName.trim() !== "")
                                             ? Plasmoid.configuration.customCpuName.trim() : autoCpuName
    readonly property string displayCpuBadge: (Plasmoid.configuration.customCpuBadge && Plasmoid.configuration.customCpuBadge.trim() !== "")
                                              ? Plasmoid.configuration.customCpuBadge.trim() : autoCpuBadge
    readonly property string displayGpuName: (Plasmoid.configuration.customGpuName && Plasmoid.configuration.customGpuName.trim() !== "")
                                             ? Plasmoid.configuration.customGpuName.trim() : autoGpuName
    readonly property string displayGpuBadge: (Plasmoid.configuration.customGpuBadge && Plasmoid.configuration.customGpuBadge.trim() !== "")
                                              ? Plasmoid.configuration.customGpuBadge.trim() : autoGpuBadge
    readonly property string displayRamName: (Plasmoid.configuration.customRamName && Plasmoid.configuration.customRamName.trim() !== "")
                                             ? Plasmoid.configuration.customRamName.trim() : autoRamName
    readonly property string displayRamBadge: (Plasmoid.configuration.customRamBadge && Plasmoid.configuration.customRamBadge.trim() !== "")
                                              ? Plasmoid.configuration.customRamBadge.trim() : autoRamBadge
    readonly property int displayRamClock: (Plasmoid.configuration.customRamClock && Plasmoid.configuration.customRamClock > 0)
                                           ? Plasmoid.configuration.customRamClock : ramClock

    // Colors
    readonly property color labelColor: Qt.rgba(215/255, 222/255, 235/255, 1)
    readonly property color subLabelColor: Qt.rgba(148/255, 163/255, 184/255, 220/255)
    readonly property color valueColor: Qt.rgba(248/255, 250/255, 252/255, 1)
    readonly property color frameColor: Qt.rgba(1, 1, 1, 28/255)
    readonly property color dividerColor: Qt.rgba(1, 1, 1, 18/255)
    readonly property color barBackColor: Qt.rgba(1, 1, 1, 28/255)
    readonly property color backgroundColor: Qt.rgba(13/255, 17/255, 28/255, 220/255)

    readonly property color cpuAccentColor: Qt.rgba(56/255, 189/255, 248/255, 1)
    readonly property color gpuAccentColor: Qt.rgba(244/255, 63/255, 94/255, 1)
    readonly property color ramAccentColor: Qt.rgba(168/255, 85/255, 247/255, 1)
    readonly property color greenColor: Qt.rgba(118/255, 211/255, 0/255, 1)

    // Live Sensor Properties
    property int cpuTemp: 40
    property int cpuPower: 25
    property real cpuUsage: 5.0
    property int cpuClock: 3600

    property int gpuTemp: 38
    property int gpuHotSpot: 42
    property real gpuUsage: 4.0
    property int gpuClock: 100
    property int gpuMemClock: 2502
    property int gpuFan: 0
    property int gpuPower: 20
    property int vramMB: 1800
    property real vramGB: 1.8
    property real vramTotalGB: 16.0
    property real vramPct: 11.2

    property real ramUsedGB: 9.5
    property real ramTotalGB: 31.8
    property real ramFreeGB: 22.3
    property real ramPct: 30.0
    property int ramClock: 2400

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/read_sensors.sh").toString().replace("file://", "")

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
    Layout.minimumHeight: 214

    function clamp01(v) {
        return Math.max(0.0, Math.min(1.0, v));
    }

    P5Support.DataSource {
        id: sensorSource
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var out = data["stdout"];
            if (out) {
                try {
                    var s = JSON.parse(out.trim());
                    if (s.cpuName) root.autoCpuName = s.cpuName;
                    if (s.cpuBadge) root.autoCpuBadge = s.cpuBadge;
                    if (s.cpuMaxClockMHz > 0) root.cpuMaxClockMHz = s.cpuMaxClockMHz;
                    if (s.gpuName) root.autoGpuName = s.gpuName;
                    if (s.gpuBadge) root.autoGpuBadge = s.gpuBadge;
                    if (s.gpuMaxPowerW > 0) root.gpuMaxPowerW = s.gpuMaxPowerW;
                    if (s.ramName) root.autoRamName = s.ramName;
                    if (s.ramBadge) root.autoRamBadge = s.ramBadge;
                    if (s.driverLabel) root.driverLabel = s.driverLabel;

                    root.cpuTemp = s.cpuTemp || 0;
                    root.cpuPower = s.cpuPower || 0;
                    root.cpuUsage = s.cpuUsage || 0;
                    root.cpuClock = s.cpuClock || 0;
                    root.gpuTemp = s.gpuTemp || 0;
                    root.gpuHotSpot = s.gpuHotSpot || 0;
                    root.gpuUsage = s.gpuUsage || 0;
                    root.gpuClock = s.gpuClock || 0;
                    root.gpuMemClock = s.gpuMemClock || 0;
                    root.gpuFan = s.gpuFan || 0;
                    root.gpuPower = s.gpuPower || 0;
                    root.vramMB = s.vramMB || 0;
                    root.vramGB = s.vramGB || 0;
                    root.vramTotalGB = s.vramTotalGB || 16.0;
                    root.vramPct = s.vramPct || 0;
                    root.ramUsedGB = s.ramUsedGB || 0;
                    root.ramTotalGB = s.ramTotalGB || 31.8;
                    root.ramFreeGB = s.ramFreeGB || 0;
                    root.ramPct = s.ramPct || 0;
                    root.ramClock = s.ramClock || 2400;
                } catch (e) {}
            }
            disconnectSource(source);
        }
    }

    Timer {
        interval: Math.max(500, Plasmoid.configuration.refreshIntervalMs || 1500)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            sensorSource.connectSource('/bin/sh "' + root.scriptPath + '"');
        }
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

            // [MeterAllBackground]
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: root.backgroundColor
                border.width: 1
                border.color: root.frameColor
            }

            // CPU Accent Pill
            Rectangle {
                x: root.padX
                y: 15
                width: 3
                height: 14
                radius: 1.5
                color: root.cpuAccentColor
            }

            // Divider 1
            Rectangle {
                x: root.padX
                y: 123
                width: root.barW
                height: 1
                color: root.dividerColor
            }

            // GPU Accent Pill
            Rectangle {
                x: root.padX
                y: 133
                width: 3
                height: 14
                radius: 1.5
                color: root.gpuAccentColor
            }

            // Divider 2
            Rectangle {
                x: root.padX
                y: 301
                width: root.barW
                height: 1
                color: root.dividerColor
            }

            // RAM Accent Pill
            Rectangle {
                x: root.padX
                y: 311
                width: 3
                height: 14
                radius: 1.5
                color: root.ramAccentColor
            }

            // Footer Divider
            Rectangle {
                x: root.padX
                y: 392
                width: root.barW
                height: 1
                color: root.dividerColor
            }

            // =========================================================================
            // SECTION 1: CPU
            // =========================================================================
            Text {
                x: root.padX + 9
                y: 13
                text: root.displayCpuName
                font.family: "Fira Sans"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 15
                text: root.displayCpuBadge
                font.family: "Fira Sans"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.subLabelColor
                renderType: Text.NativeRendering
            }

            // --- Row 1: CPU Temp & Power ---
            Text {
                x: root.padX
                y: 36
                text: "Temperatura / Potência"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 36
                text: root.cpuTemp + " °C  |  " + root.cpuPower + " W"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 54
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01((root.cpuTemp - 25) / (root.cpuMaxTemp - 25)) * root.barW
                    height: 3
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: Qt.rgba(56/255, 189/255, 248/255, 1) }
                        GradientStop { position: 0.55; color: Qt.rgba(118/255, 211/255, 0/255, 1) }
                        GradientStop { position: 0.80; color: Qt.rgba(235/255, 227/255, 21/255, 1) }
                        GradientStop { position: 1.00; color: Qt.rgba(240/255, 19/255, 19/255, 1) }
                    }
                }
            }

            // --- Row 2: CPU Usage ---
            Text {
                x: root.padX
                y: 63
                text: "Uso da CPU"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 63
                text: root.cpuUsage.toFixed(1) + " %"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 81
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01(root.cpuUsage / 100.0) * root.barW
                    height: 3
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: Qt.rgba(56/255, 189/255, 248/255, 1) }
                        GradientStop { position: 0.60; color: Qt.rgba(118/255, 211/255, 0/255, 1) }
                        GradientStop { position: 0.85; color: Qt.rgba(235/255, 227/255, 21/255, 1) }
                        GradientStop { position: 1.00; color: Qt.rgba(240/255, 19/255, 19/255, 1) }
                    }
                }
            }

            // --- Row 3: CPU Clock ---
            Text {
                x: root.padX
                y: 90
                text: "Clock da CPU"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 90
                text: root.cpuClock + " MHz"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 108
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01(root.cpuClock / root.cpuMaxClockMHz) * root.barW
                    height: 3
                    radius: 1.5
                    color: root.cpuAccentColor
                }
            }

            // =========================================================================
            // SECTION 2: GPU
            // =========================================================================
            Text {
                x: root.padX + 9
                y: 131
                text: root.displayGpuName
                font.family: "Fira Sans"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 133
                text: root.displayGpuBadge
                font.family: "Fira Sans"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.subLabelColor
                renderType: Text.NativeRendering
            }

            // --- Row 4: GPU Temp & Hot Spot ---
            Text {
                x: root.padX
                y: 154
                text: "GPU Temp / Hot Spot"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 154
                text: root.gpuTemp + " °C / " + root.gpuHotSpot + " °C"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 172
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01((root.gpuTemp - 25) / (root.gpuMaxTemp - 25)) * root.barW
                    height: 3
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: Qt.rgba(118/255, 211/255, 0/255, 1) }
                        GradientStop { position: 0.50; color: Qt.rgba(118/255, 211/255, 0/255, 1) }
                        GradientStop { position: 0.80; color: Qt.rgba(235/255, 227/255, 21/255, 1) }
                        GradientStop { position: 1.00; color: Qt.rgba(240/255, 19/255, 19/255, 1) }
                    }
                }
            }

            // --- Row 5: GPU Usage ---
            Text {
                x: root.padX
                y: 181
                text: "Uso da GPU"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 181
                text: root.gpuUsage.toFixed(1) + " %"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 199
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01(root.gpuUsage / 100.0) * root.barW
                    height: 3
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: Qt.rgba(118/255, 211/255, 0/255, 1) }
                        GradientStop { position: 0.55; color: Qt.rgba(118/255, 211/255, 0/255, 1) }
                        GradientStop { position: 0.85; color: Qt.rgba(235/255, 227/255, 21/255, 1) }
                        GradientStop { position: 1.00; color: Qt.rgba(240/255, 19/255, 19/255, 1) }
                    }
                }
            }

            // --- Row 6: GPU Clock & Memory Clock ---
            Text {
                x: root.padX
                y: 208
                text: "Clock GPU / Memória"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 208
                text: root.gpuClock + " / " + root.gpuMemClock + " MHz"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 226
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01(root.gpuClock / root.gpuMaxClockMHz) * root.barW
                    height: 3
                    radius: 1.5
                    color: root.gpuAccentColor
                }
            }

            // --- Row 7: GPU Fan & Power ---
            Text {
                x: root.padX
                y: 235
                text: "Cooler Fan / Potência"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 235
                text: root.gpuFan + " RPM  |  " + root.gpuPower + " W"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 253
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01(root.gpuPower / root.gpuMaxPowerW) * root.barW
                    height: 3
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: Qt.rgba(118/255, 211/255, 0/255, 1) }
                        GradientStop { position: 0.75; color: Qt.rgba(235/255, 227/255, 21/255, 1) }
                        GradientStop { position: 1.00; color: Qt.rgba(240/255, 19/255, 19/255, 1) }
                    }
                }
            }

            // --- Row 8: GPU VRAM ---
            Text {
                x: root.padX
                y: 262
                width: root.barW - vramValText.implicitWidth - 6
                elide: Text.ElideRight
                text: "Memória de Vídeo (VRAM)"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                id: vramValText
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 262
                text: root.vramMB + " MB (" + root.vramGB.toFixed(1) + "/" + root.vramTotalGB.toFixed(1) + " GB • " + root.vramPct.toFixed(1) + "%)"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 280
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01(root.vramPct / 100.0) * root.barW
                    height: 3
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: Qt.rgba(244/255, 63/255, 94/255, 1) }
                        GradientStop { position: 0.75; color: Qt.rgba(245/255, 158/255, 11/255, 1) }
                        GradientStop { position: 1.00; color: Qt.rgba(240/255, 19/255, 19/255, 1) }
                    }
                }
            }

            // =========================================================================
            // SECTION 3: RAM
            // =========================================================================
            Text {
                x: root.padX + 9
                y: 309
                text: root.displayRamName
                font.family: "Fira Sans"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 311
                text: root.displayRamBadge
                font.family: "Fira Sans"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.subLabelColor
                renderType: Text.NativeRendering
            }

            // --- Row 9: RAM Used & Percentage ---
            Text {
                x: root.padX
                y: 332
                text: "RAM em Uso"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 332
                text: root.ramUsedGB.toFixed(1) + " / " + root.ramTotalGB.toFixed(1) + " GB (" + root.ramPct.toFixed(1) + "%)"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 350
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01(root.ramPct / 100.0) * root.barW
                    height: 3
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: Qt.rgba(168/255, 85/255, 247/255, 1) }
                        GradientStop { position: 0.65; color: Qt.rgba(56/255, 189/255, 248/255, 1) }
                        GradientStop { position: 0.85; color: Qt.rgba(235/255, 227/255, 21/255, 1) }
                        GradientStop { position: 1.00; color: Qt.rgba(240/255, 19/255, 19/255, 1) }
                    }
                }
            }

            // --- Row 10: RAM Free & Clock ---
            Text {
                x: root.padX
                y: 359
                text: "RAM Disponível / Clock"
                font.family: "Fira Sans"
                font.pixelSize: 12
                color: root.labelColor
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 359
                text: root.ramFreeGB.toFixed(1) + " GB Livre  |  " + root.displayRamClock + " MHz"
                font.family: "Fira Sans"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.valueColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                x: root.padX
                y: 377
                width: root.barW
                height: 3
                radius: 1.5
                color: root.barBackColor

                Rectangle {
                    width: root.clamp01((100.0 - root.ramPct) / 100.0) * root.barW
                    height: 3
                    radius: 1.5
                    color: root.ramAccentColor
                }
            }

            // =========================================================================
            // FOOTER: STATUS & QUICK LAUNCHER
            // =========================================================================
            Text {
                x: root.padX
                y: 401
                width: root.barW - footerRightText.implicitWidth - 8
                elide: Text.ElideRight
                text: root.driverLabel
                font.family: "Fira Sans"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.greenColor
                renderType: Text.NativeRendering
            }

            Text {
                id: footerRightText
                anchors.right: parent.right
                anchors.rightMargin: root.padX
                y: 401
                text: Plasmoid.configuration.footerButtonText || "Beszel ↗"
                font.family: "Fira Sans"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.subLabelColor
                renderType: Text.NativeRendering
            }

            MouseArea {
                x: 0
                y: 392
                width: root.cardW
                height: 36
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var url = (Plasmoid.configuration.footerClickUrl || "http://localhost:8090").trim();
                    if (url !== "") Qt.openUrlExternally(url);
                }
            }
        }
    }
}
