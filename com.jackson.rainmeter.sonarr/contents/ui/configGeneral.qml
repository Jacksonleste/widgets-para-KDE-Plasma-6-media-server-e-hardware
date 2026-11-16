import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_sonarrUrl: sonarrUrlField.text
    property alias cfg_clickUrl: clickUrlField.text
    property alias cfg_sonarrKey: sonarrKeyField.text
    property alias cfg_jellyfinUrl: jellyfinUrlField.text
    property alias cfg_jellyfinToken: jellyfinTokenField.text
    property alias cfg_titleText: titleField.text
    property alias cfg_subtitleText: subtitleField.text
    property alias cfg_refreshIntervalSec: refreshSpin.value

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Conexão da API do Sonarr"
        }

        TextField {
            id: sonarrUrlField
            Kirigami.FormData.label: "URL do Sonarr:"
            placeholderText: "http://localhost:8989"
            Layout.fillWidth: true
        }

        RowLayout {
            Kirigami.FormData.label: "API Key do Sonarr:"
            Layout.fillWidth: true

            TextField {
                id: sonarrKeyField
                placeholderText: "Cole aqui sua API Key do Sonarr"
                echoMode: showSonarrBtn.checked ? TextInput.Normal : TextInput.Password
                Layout.fillWidth: true
            }

            ToolButton {
                id: showSonarrBtn
                checkable: true
                icon.name: checked ? "view-hidden" : "view-visible"
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Ocultar chave" : "Mostrar chave"
            }
        }

        TextField {
            id: clickUrlField
            Kirigami.FormData.label: "URL ao clicar (opcional):"
            placeholderText: "Deixe vazio para usar a mesma URL do Sonarr"
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Contagem de Séries (Opcional: Jellyfin)"
        }

        TextField {
            id: jellyfinUrlField
            Kirigami.FormData.label: "URL do Jellyfin:"
            placeholderText: "http://localhost:8096"
            Layout.fillWidth: true
        }

        RowLayout {
            Kirigami.FormData.label: "Token do Jellyfin:"
            Layout.fillWidth: true

            TextField {
                id: jellyfinTokenField
                placeholderText: "Vazio = contar séries direto pelo Sonarr"
                echoMode: showJfBtn.checked ? TextInput.Normal : TextInput.Password
                Layout.fillWidth: true
            }

            ToolButton {
                id: showJfBtn
                checkable: true
                icon.name: checked ? "view-hidden" : "view-visible"
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Ocultar chave" : "Mostrar chave"
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Aparência e Atualização"
        }

        TextField {
            id: titleField
            Kirigami.FormData.label: "Título do Card:"
            placeholderText: "Sonarr"
            Layout.fillWidth: true
        }

        TextField {
            id: subtitleField
            Kirigami.FormData.label: "Subtítulo:"
            placeholderText: "Gerenciamento de Séries"
            Layout.fillWidth: true
        }

        SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: "Intervalo de atualização (s):"
            from: 5
            to: 600
        }
    }
}
