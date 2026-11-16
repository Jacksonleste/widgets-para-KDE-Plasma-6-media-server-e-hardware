import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_qbitUrl: qbitUrlField.text
    property alias cfg_clickUrl: clickUrlField.text
    property alias cfg_qbitUsername: usernameField.text
    property alias cfg_qbitPassword: passwordField.text
    property alias cfg_titleText: titleField.text
    property alias cfg_subtitleText: subtitleField.text
    property alias cfg_refreshIntervalSec: refreshSpin.value

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Conexão da WebUI do qBittorrent"
        }

        TextField {
            id: qbitUrlField
            Kirigami.FormData.label: "URL do qBittorrent:"
            placeholderText: "http://localhost:8080"
            Layout.fillWidth: true
        }

        TextField {
            id: usernameField
            Kirigami.FormData.label: "Usuário:"
            placeholderText: "admin"
            Layout.fillWidth: true
        }

        RowLayout {
            Kirigami.FormData.label: "Senha:"
            Layout.fillWidth: true

            TextField {
                id: passwordField
                placeholderText: "Senha da WebUI do qBittorrent"
                echoMode: showPassBtn.checked ? TextInput.Normal : TextInput.Password
                Layout.fillWidth: true
            }

            ToolButton {
                id: showPassBtn
                checkable: true
                icon.name: checked ? "view-hidden" : "view-visible"
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Ocultar senha" : "Mostrar senha"
            }
        }

        TextField {
            id: clickUrlField
            Kirigami.FormData.label: "URL ao clicar (opcional):"
            placeholderText: "Deixe vazio para usar a mesma URL do qBittorrent"
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Aparência e Atualização"
        }

        TextField {
            id: titleField
            Kirigami.FormData.label: "Título do Card:"
            placeholderText: "qBittorrent"
            Layout.fillWidth: true
        }

        TextField {
            id: subtitleField
            Kirigami.FormData.label: "Subtítulo:"
            placeholderText: "Cliente de Transferência de Torrents"
            Layout.fillWidth: true
        }

        SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: "Intervalo de atualização (s):"
            from: 1
            to: 120
        }
    }
}
