#!/bin/sh
# ==============================================================================
# Gerenciador de Instalação e Desinstalação — KDE Plasma 6 Widgets
# Suporta interface gráfica nativa do KDE (kdialog), TUI (whiptail) e CLI.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLASMOIDS_DIR="$HOME/.local/share/plasma/plasmoids"
FONTS_DIR="$HOME/.local/share/fonts/FiraSans"
QML_CACHE_DIR="$HOME/.cache/plasmashell/qmlcache"

ALL_WIDGETS="io.system.hwmonitor io.mediaserver.jellyfin io.mediaserver.radarr io.mediaserver.sonarr io.mediaserver.prowlarr io.mediaserver.qbittorrent"

widget_name() {
    case "$1" in
        io.system.hwmonitor)        echo "Monitor de Hardware (CPU, GPU e RAM)" ;;
        io.mediaserver.jellyfin)    echo "Jellyfin (Biblioteca e Now Playing)" ;;
        io.mediaserver.radarr)      echo "Radarr (Gerenciamento de Filmes)" ;;
        io.mediaserver.sonarr)      echo "Sonarr (Gerenciamento de Séries)" ;;
        io.mediaserver.prowlarr)    echo "Prowlarr (Estatísticas de Indexadores)" ;;
        io.mediaserver.qbittorrent) echo "qBittorrent (Transferência de Torrents)" ;;
        *) echo "$1" ;;
    esac
}

is_installed() {
    [ -e "$PLASMOIDS_DIR/$1" ] || [ -L "$PLASMOIDS_DIR/$1" ]
}

any_widget_installed() {
    for w in $ALL_WIDGETS; do
        if is_installed "$w"; then
            return 0
        fi
    done
    return 1
}

install_fonts() {
    if [ -d "$SCRIPT_DIR/fonts" ]; then
        mkdir -p "$FONTS_DIR"
        cp -f "$SCRIPT_DIR/fonts/"*.otf "$FONTS_DIR/" 2>/dev/null || true
        fc-cache -f "$FONTS_DIR" 2>/dev/null || true
    fi
}

remove_from_plasma_desktop() {
    # Remove instâncias ativas da área de trabalho do KDE via DBus para não deixar widgets quebrados nem lixo no appletsrc
    TARGETS="$1"
    [ -z "$TARGETS" ] && return 0

    JS_ARRAY=""
    for w in $TARGETS; do
        if [ -z "$JS_ARRAY" ]; then
            JS_ARRAY="\"$w\""
        else
            JS_ARRAY="$JS_ARRAY, \"$w\""
        fi
    done

    QDBUS_CMD=""
    if command -v qdbus6 >/dev/null 2>&1; then
        QDBUS_CMD="qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        QDBUS_CMD="qdbus"
    fi

    if [ -n "$QDBUS_CMD" ]; then
        "$QDBUS_CMD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var targets = [$JS_ARRAY];
            var ds = desktops();
            for (var i = 0; i < ds.length; i++) {
                var ws = ds[i].widgets();
                for (var j = 0; j < ws.length; j++) {
                    if (targets.indexOf(ws[j].type) !== -1) {
                        ws[j].remove();
                    }
                }
            }
            var ps = panels();
            for (var k = 0; k < ps.length; k++) {
                var pws = ps[k].widgets();
                for (var m = 0; m < pws.length; m++) {
                    if (targets.indexOf(pws[m].type) !== -1) {
                        pws[m].remove();
                    }
                }
            }
        " >/dev/null 2>&1 || true
    fi
}

reload_plasma_cache() {
    rm -f /dev/shm/hwmonitor_static /dev/shm/hwmonitor_state /dev/shm/rm_hw_static_v2 /dev/shm/rm_hw_state 2>/dev/null || true
    rm -rf "$QML_CACHE_DIR/"* 2>/dev/null || true
}

do_install_widgets() {
    MODE="$1" # "copy" ou "symlink"
    SELECTED="$2"
    [ -z "$SELECTED" ] && return 0

    install_fonts
    mkdir -p "$PLASMOIDS_DIR"
    chmod +x "$SCRIPT_DIR/io.system.hwmonitor/contents/scripts/read_sensors.sh" 2>/dev/null || true

    for w in $SELECTED; do
        w=$(echo "$w" | tr -d '"')
        [ ! -d "$SCRIPT_DIR/$w" ] && continue
        rm -rf "$PLASMOIDS_DIR/$w"
        if [ "$MODE" = "symlink" ]; then
            ln -s "$SCRIPT_DIR/$w" "$PLASMOIDS_DIR/$w"
        else
            cp -r "$SCRIPT_DIR/$w" "$PLASMOIDS_DIR/$w"
            chmod +x "$PLASMOIDS_DIR/$w/contents/scripts/"*.sh 2>/dev/null || true
        fi
    done

    reload_plasma_cache
}

do_uninstall_widgets() {
    SELECTED="$1"
    [ -z "$SELECTED" ] && return 0

    CLEAN_LIST=""
    for w in $SELECTED; do
        w=$(echo "$w" | tr -d '"')
        CLEAN_LIST="$CLEAN_LIST $w"
    done

    # 1. Remove da área de trabalho e limpa entradas no plasma-org.kde.plasma.desktop-appletsrc
    remove_from_plasma_desktop "$CLEAN_LIST"

    # 2. Remove os pacotes em ~/.local/share/plasma/plasmoids
    for w in $CLEAN_LIST; do
        rm -rf "$PLASMOIDS_DIR/$w"
        if [ "$w" = "io.system.hwmonitor" ]; then
            rm -f /dev/shm/hwmonitor_static /dev/shm/hwmonitor_state 2>/dev/null || true
        fi
    done

    # 3. Se nenhum widget do pacote restar instalado, remove também a pasta de fontes FiraSans
    if ! any_widget_installed; then
        if [ -d "$FONTS_DIR" ]; then
            rm -rf "$FONTS_DIR"
            fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
        fi
    fi

    # 4. Limpa cache QML
    reload_plasma_cache
}

# ==============================================================================
# Modo Linha de Comando Direto (Flags)
# ==============================================================================
case "${1:-}" in
    --dev)
        do_install_widgets "symlink" "$ALL_WIDGETS"
        echo "Todos os 6 widgets foram vinculados (modo symlink/dev) em $PLASMOIDS_DIR"
        exit 0
        ;;
    --install-all)
        do_install_widgets "copy" "$ALL_WIDGETS"
        echo "Todos os 6 widgets foram instalados (cópia independente) em $PLASMOIDS_DIR"
        exit 0
        ;;
    --uninstall-all)
        do_uninstall_widgets "$ALL_WIDGETS"
        echo "Todos os widgets, fontes e caches temporários foram completamente removidos."
        exit 0
        ;;
    --help|-h)
        echo "Uso: ./install.sh [opção]"
        echo "  (sem argumentos)  Abre o instalador/desinstalador interativo (GUI kdialog ou Terminal)"
        echo "  --install-all     Instala todos os 6 widgets (copiando arquivos)"
        echo "  --dev             Instala todos os 6 widgets via link simbólico (para edição)"
        echo "  --uninstall-all   Remove todos os widgets, fontes, instâncias da área de trabalho e caches"
        exit 0
        ;;
esac

# ==============================================================================
# Modo Interativo Gráfico (kdialog — Nativo do KDE Plasma)
# ==============================================================================
if command -v kdialog >/dev/null 2>&1 && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; } && [ "${1:-}" != "--cli" ]; then
    ACTION=$(kdialog --title "Gerenciador de Widgets KDE Plasma" \
        --menu "Escolha o que deseja fazer:" \
        "install"   "📦 Instalar ou Atualizar Widgets (escolher quais)" \
        "uninstall" "🗑️ Desinstalar Widgets específicos" \
        "purge"     "🧹 Desinstalação Completa (remover tudo sem deixar vestígios)" \
        "dev"       "🔗 Instalar em Modo Edição (Links Simbólicos)" \
        2>/dev/null) || exit 0

    case "$ACTION" in
        install|dev)
            MODE="copy"
            [ "$ACTION" = "dev" ] && MODE="symlink"
            SELECTED=$(kdialog --title "Selecionar Widgets para Instalar" \
                --separate-output \
                --checklist "Marque os widgets que deseja instalar no KDE Plasma:" \
                "io.system.hwmonitor"        "$(widget_name io.system.hwmonitor)" on \
                "io.mediaserver.jellyfin"    "$(widget_name io.mediaserver.jellyfin)" on \
                "io.mediaserver.radarr"      "$(widget_name io.mediaserver.radarr)" on \
                "io.mediaserver.sonarr"      "$(widget_name io.mediaserver.sonarr)" on \
                "io.mediaserver.prowlarr"    "$(widget_name io.mediaserver.prowlarr)" on \
                "io.mediaserver.qbittorrent" "$(widget_name io.mediaserver.qbittorrent)" on \
                2>/dev/null) || exit 0

            if [ -z "$SELECTED" ]; then
                kdialog --title "Aviso" --sorry "Nenhum widget foi selecionado." 2>/dev/null
                exit 0
            fi

            do_install_widgets "$MODE" "$SELECTED"
            kdialog --title "Instalação Concluída" \
                --msgbox "Os widgets selecionados foram instalados com sucesso!\n\nPara adicioná-los: clique com o botão direito na Área de Trabalho → 'Adicionar ou gerenciar widgets...'" 2>/dev/null
            ;;

        uninstall)
            if ! any_widget_installed; then
                kdialog --title "Aviso" --sorry "Nenhum widget deste pacote está instalado no momento." 2>/dev/null
                exit 0
            fi

            SELECTED=$(kdialog --title "Desinstalar Widgets" \
                --separate-output \
                --checklist "Marque os widgets que deseja remover completamente:" \
                "io.system.hwmonitor"        "$(widget_name io.system.hwmonitor)" off \
                "io.mediaserver.jellyfin"    "$(widget_name io.mediaserver.jellyfin)" off \
                "io.mediaserver.radarr"      "$(widget_name io.mediaserver.radarr)" off \
                "io.mediaserver.sonarr"      "$(widget_name io.mediaserver.sonarr)" off \
                "io.mediaserver.prowlarr"    "$(widget_name io.mediaserver.prowlarr)" off \
                "io.mediaserver.qbittorrent" "$(widget_name io.mediaserver.qbittorrent)" off \
                2>/dev/null) || exit 0

            [ -z "$SELECTED" ] && exit 0
            do_uninstall_widgets "$SELECTED"
            kdialog --title "Desinstalação Concluída" \
                --msgbox "Os widgets selecionados foram removidos da Área de Trabalho e do sistema sem deixar arquivos remanescentes." 2>/dev/null
            ;;

        purge)
            if kdialog --title "Confirmar Remoção Completa" \
                --yesno "Deseja remover TODOS os widgets deste pacote, retirá-los da área de trabalho, remover as fontes instaladas e limpar todos os caches?" 2>/dev/null; then
                do_uninstall_widgets "$ALL_WIDGETS"
                kdialog --title "Limpeza Concluída" \
                    --msgbox "Todos os widgets, fontes (Fira Sans) e arquivos temporários de cache foram removidos do sistema!" 2>/dev/null
            fi
            ;;
    esac
    exit 0
fi

# ==============================================================================
# Fallback Interativo no Terminal (CLI Menu)
# ==============================================================================
echo "=========================================================="
echo "   Gerenciador de Widgets — KDE Plasma 6"
echo "=========================================================="
echo "1) Instalar Widgets (escolher quais - cópia independente)"
echo "2) Instalar Todos os 6 Widgets"
echo "3) Instalar Todos em Modo Edição (Links Simbólicos)"
echo "4) Desinstalar Widgets específicos"
echo "5) Desinstalação Completa (Remover tudo + fontes + caches)"
echo "0) Sair"
echo "----------------------------------------------------------"
printf "Escolha uma opção [0-5]: "
read -r OPT

case "$OPT" in
    1)
        SELECTED=""
        for w in $ALL_WIDGETS; do
            printf "Instalar %s? [S/n]: " "$(widget_name "$w")"
            read -r ANS
            case "$ANS" in
                [nN]*) ;;
                *) SELECTED="$SELECTED $w" ;;
            esac
        done
        do_install_widgets "copy" "$SELECTED"
        echo "Concluído! Widgets instalados com sucesso."
        ;;
    2)
        do_install_widgets "copy" "$ALL_WIDGETS"
        echo "Concluído! Todos os 6 widgets foram instalados."
        ;;
    3)
        do_install_widgets "symlink" "$ALL_WIDGETS"
        echo "Concluído! Todos os 6 widgets foram vinculados via link simbólico."
        ;;
    4)
        SELECTED=""
        for w in $ALL_WIDGETS; do
            if is_installed "$w"; then
                printf "Remover %s? [s/N]: " "$(widget_name "$w")"
                read -r ANS
                case "$ANS" in
                    [sS]*|[yY]*) SELECTED="$SELECTED $w" ;;
                esac
            fi
        done
        do_uninstall_widgets "$SELECTED"
        echo "Concluído! Widgets selecionados removidos sem deixar vestígios."
        ;;
    5)
        do_uninstall_widgets "$ALL_WIDGETS"
        echo "Limpeza completa concluída! Nenhum arquivo remanescente ficou no sistema."
        ;;
    *)
        exit 0
        ;;
esac
