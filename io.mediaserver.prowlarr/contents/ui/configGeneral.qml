import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_prowlarrUrl: prowlarrUrlField.text
    property alias cfg_clickUrl: clickUrlField.text
    property alias cfg_prowlarrKey: prowlarrKeyField.text
    property alias cfg_titleText: titleField.text
    property alias cfg_subtitleText: subtitleField.text
    property alias cfg_refreshIntervalSec: refreshSpin.value

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Conexão da API do Prowlarr"
        }

        TextField {
            id: prowlarrUrlField
            Kirigami.FormData.label: "URL do Prowlarr:"
            placeholderText: "http://localhost:9696"
            Layout.fillWidth: true
        }

        RowLayout {
            Kirigami.FormData.label: "API Key do Prowlarr:"
            Layout.fillWidth: true

            TextField {
                id: prowlarrKeyField
                placeholderText: "Cole aqui sua API Key do Prowlarr"
                echoMode: showKeyBtn.checked ? TextInput.Normal : TextInput.Password
                Layout.fillWidth: true
            }

            ToolButton {
                id: showKeyBtn
                checkable: true
                icon.name: checked ? "view-hidden" : "view-visible"
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Ocultar chave" : "Mostrar chave"
            }
        }

        TextField {
            id: clickUrlField
            Kirigami.FormData.label: "URL ao clicar (opcional):"
            placeholderText: "Deixe vazio para usar a mesma URL do Prowlarr"
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Aparência e Atualização"
        }

        TextField {
            id: titleField
            Kirigami.FormData.label: "Título do Card:"
            placeholderText: "Prowlarr"
            Layout.fillWidth: true
        }

        TextField {
            id: subtitleField
            Kirigami.FormData.label: "Subtítulo:"
            placeholderText: "Gerenciamento Central de Indexadores"
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
