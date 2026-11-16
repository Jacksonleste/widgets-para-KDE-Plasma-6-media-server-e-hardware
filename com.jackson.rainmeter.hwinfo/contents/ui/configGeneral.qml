import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_customCpuName: cpuNameField.text
    property alias cfg_customCpuBadge: cpuBadgeField.text
    property alias cfg_customGpuName: gpuNameField.text
    property alias cfg_customGpuBadge: gpuBadgeField.text
    property alias cfg_customRamName: ramNameField.text
    property alias cfg_customRamBadge: ramBadgeField.text
    property alias cfg_customRamClock: ramClockSpin.value
    property alias cfg_footerButtonText: footerBtnField.text
    property alias cfg_footerClickUrl: footerUrlField.text
    property alias cfg_refreshIntervalMs: refreshSpin.value

    Kirigami.FormLayout {
        Label {
            text: "Todos os campos abaixo são detectados automaticamente do sistema.\nPreencha apenas se quiser substituir algum nome ou valor manualmente."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            opacity: 0.8
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Processador (CPU)"
        }

        TextField {
            id: cpuNameField
            Kirigami.FormData.label: "Nome da CPU:"
            placeholderText: "Automático (ex: AMD Ryzen 7 5700X)"
            Layout.fillWidth: true
        }

        TextField {
            id: cpuBadgeField
            Kirigami.FormData.label: "Núcleos / Threads:"
            placeholderText: "Automático (ex: 8C / 16T)"
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Placa de Vídeo (GPU)"
        }

        TextField {
            id: gpuNameField
            Kirigami.FormData.label: "Nome da GPU:"
            placeholderText: "Automático (ex: Radeon RX 9060 XT)"
            Layout.fillWidth: true
        }

        TextField {
            id: gpuBadgeField
            Kirigami.FormData.label: "VRAM / Tipo:"
            placeholderText: "Automático (ex: 16 GB GDDR6)"
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Memória RAM"
        }

        TextField {
            id: ramNameField
            Kirigami.FormData.label: "Título da RAM:"
            placeholderText: "Automático (ex: Memória RAM DDR4)"
            Layout.fillWidth: true
        }

        TextField {
            id: ramBadgeField
            Kirigami.FormData.label: "Capacidade / Canal:"
            placeholderText: "Automático (ex: 32 GB Dual-Channel)"
            Layout.fillWidth: true
        }

        SpinBox {
            id: ramClockSpin
            Kirigami.FormData.label: "Clock da RAM (MHz, 0 = Auto):"
            from: 0
            to: 10000
            stepSize: 100
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Rodapé e Atualização"
        }

        TextField {
            id: footerBtnField
            Kirigami.FormData.label: "Texto do atalho:"
            placeholderText: "Beszel ↗"
            Layout.fillWidth: true
        }

        TextField {
            id: footerUrlField
            Kirigami.FormData.label: "URL ao clicar no rodapé:"
            placeholderText: "http://localhost:8090"
            Layout.fillWidth: true
        }

        SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: "Intervalo de leitura (ms):"
            from: 500
            to: 10000
            stepSize: 250
        }
    }
}
