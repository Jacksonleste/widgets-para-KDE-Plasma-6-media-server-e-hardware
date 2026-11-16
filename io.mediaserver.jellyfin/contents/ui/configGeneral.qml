import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_apiUrl: apiUrlField.text
    property alias cfg_clickActionMode: actionModeCombo.currentIndex
    property alias cfg_clientCommand: clientCommandField.text
    property alias cfg_clickUrl: clickUrlField.text
    property alias cfg_apiToken: apiTokenField.text
    property alias cfg_titleText: titleField.text
    property alias cfg_subtitleText: subtitleField.text
    property alias cfg_sessionsIntervalSec: sessionsSpin.value
    property alias cfg_countsIntervalSec: countsSpin.value

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Conexão da API do Jellyfin"
        }

        TextField {
            id: apiUrlField
            Kirigami.FormData.label: "URL do Jellyfin:"
            placeholderText: "http://localhost:8096"
            Layout.fillWidth: true
        }

        RowLayout {
            Kirigami.FormData.label: "Chave de API (Token):"
            Layout.fillWidth: true

            TextField {
                id: apiTokenField
                placeholderText: "Cole aqui sua API Key do Jellyfin"
                echoMode: showTokenBtn.checked ? TextInput.Normal : TextInput.Password
                Layout.fillWidth: true
            }

            ToolButton {
                id: showTokenBtn
                checkable: true
                icon.name: checked ? "view-hidden" : "view-visible"
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Ocultar chave" : "Mostrar chave"
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Ação ao Clicar no Card"
        }

        ComboBox {
            id: actionModeCombo
            Kirigami.FormData.label: "Ao clicar no widget:"
            Layout.fillWidth: true
            model: [
                "Auto-detectar Cliente Desktop (ou abrir Navegador)",
                "Abrir Cliente Desktop (Comando / Programa)",
                "Abrir Interface Web no Navegador"
            ]
        }

        ComboBox {
            id: presetCombo
            Kirigami.FormData.label: "Predefinições de Cliente:"
            visible: actionModeCombo.currentIndex !== 2
            Layout.fillWidth: true
            model: [
                "Selecionar cliente conhecido...",
                "Jellium Desktop (jellium-desktop)",
                "Jellium Desktop (Flatpak)",
                "Jellyfin Media Player (jellyfinmediaplayer)",
                "Jellyfin Media Player (Flatpak)",
                "Delfin (delfin)",
                "Delfin (Flatpak)",
                "Feishin (feishin)"
            ]
            onActivated: function(index) {
                var cmds = [
                    "",
                    "jellium-desktop",
                    "flatpak run net.nullsum.JelliumDesktop",
                    "jellyfinmediaplayer",
                    "flatpak run com.github.iwalton3.jellyfin-media-player",
                    "delfin",
                    "flatpak run cafe.avery.Delfin",
                    "feishin"
                ];
                if (index > 0 && cmds[index]) {
                    clientCommandField.text = cmds[index];
                }
            }
        }

        TextField {
            id: clientCommandField
            Kirigami.FormData.label: "Comando do Cliente:"
            visible: actionModeCombo.currentIndex !== 2
            placeholderText: "Ex: jellium-desktop, jellyfinmediaplayer..."
            Layout.fillWidth: true
        }

        TextField {
            id: clickUrlField
            Kirigami.FormData.label: "URL Web (alternativa):"
            placeholderText: "Deixe vazio para usar a mesma URL do servidor"
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Aparência e Atualização"
        }

        TextField {
            id: titleField
            Kirigami.FormData.label: "Título do Card:"
            placeholderText: "Jellyfin"
            Layout.fillWidth: true
        }

        TextField {
            id: subtitleField
            Kirigami.FormData.label: "Subtítulo:"
            placeholderText: "Servidor de Streaming"
            Layout.fillWidth: true
        }

        SpinBox {
            id: sessionsSpin
            Kirigami.FormData.label: "Atualizar Now Playing (s):"
            from: 1
            to: 60
        }

        SpinBox {
            id: countsSpin
            Kirigami.FormData.label: "Atualizar Biblioteca (s):"
            from: 5
            to: 600
        }
    }
}
