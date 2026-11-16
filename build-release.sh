#!/bin/sh
# ==============================================================================
# Gerador de Pacotes para GitHub Release (.plasmoid individuais + bundle .zip)
# - Embute as fontes Fira Sans dentro de cada .plasmoid (via QML FontLoader)
# - Remove chaves de API e senhas pessoais dos arquivos gerados para a Release
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASE_DIR="$SCRIPT_DIR/release"
STAGE_DIR="/dev/shm/plasmoid_release_stage"

ALL_WIDGETS="io.mediaserver.jellyfin io.mediaserver.radarr io.mediaserver.sonarr io.mediaserver.prowlarr io.mediaserver.qbittorrent io.system.hwmonitor"
NEEDED_FONTS="FiraSans-Regular.otf FiraSans-Medium.otf FiraSans-SemiBold.otf FiraSans-Bold.otf"

# 1. Garante que as 4 fontes principais estejam dentro de contents/fonts/ de cada widget
for w in $ALL_WIDGETS; do
    mkdir -p "$SCRIPT_DIR/$w/contents/fonts"
    for f in $NEEDED_FONTS; do
        if [ -f "$SCRIPT_DIR/fonts/$f" ]; then
            cp -f "$SCRIPT_DIR/fonts/$f" "$SCRIPT_DIR/$w/contents/fonts/$f"
        fi
    done
done

# 2. Prepara diretório temporário de staging (para limpar chaves/senhas sem afetar seu uso local)
rm -rf "$STAGE_DIR" "$RELEASE_DIR"
mkdir -p "$STAGE_DIR/bundle" "$RELEASE_DIR"

for w in $ALL_WIDGETS; do
    cp -r "$SCRIPT_DIR/$w" "$STAGE_DIR/bundle/$w"
    # Limpa chaves de API e senhas nos pacotes de distribuição pública
    XML_FILE="$STAGE_DIR/bundle/$w/contents/config/main.xml"
    if [ -f "$XML_FILE" ]; then
        sed -i -E '
            /<entry name="(apiToken|radarrKey|sonarrKey|prowlarrKey|jellyfinToken|qbitPassword)"/,/<\/entry>/ {
                s|<default>[^<]*</default>|<default></default>|g
            }
        ' "$XML_FILE"
    fi

    # Empacota cada widget individual como .plasmoid (compatível com "Instalar widget a partir de arquivo local...")
    python3 -c "
import os, zipfile
src = '$STAGE_DIR/bundle/$w'
out = '$RELEASE_DIR/$w.plasmoid'
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(src):
        for file in sorted(files):
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, src)
            zf.write(full_path, rel_path)
"
    echo "✔ Gerado: release/$w.plasmoid"
done

# 3. Gera também o bundle completo (.zip) com o instalador interativo
cp -r "$SCRIPT_DIR/fonts" "$STAGE_DIR/bundle/fonts"
cp "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/uninstall.sh" "$SCRIPT_DIR/reload.sh" "$SCRIPT_DIR/README.md" "$STAGE_DIR/bundle/"
if [ -d "$SCRIPT_DIR/screenshots" ]; then
    cp -r "$SCRIPT_DIR/screenshots" "$STAGE_DIR/bundle/screenshots"
fi

python3 -c "
import os, zipfile
src = '$STAGE_DIR/bundle'
out = '$RELEASE_DIR/kde-media-hardware-widgets-bundle.zip'
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(src):
        for file in sorted(files):
            full_path = os.path.join(root, file)
            rel_path = os.path.join('kde-media-hardware-widgets', os.path.relpath(full_path, src))
            zf.write(full_path, rel_path)
"
echo "✔ Gerado: release/kde-media-hardware-widgets-bundle.zip"

rm -rf "$STAGE_DIR"
echo ""
echo "Todos os pacotes de Release estão prontos em: $RELEASE_DIR"
