#!/bin/sh
# Atalho direto para desinstalação completa sem arquivos remanescentes
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/install.sh" --uninstall-all
