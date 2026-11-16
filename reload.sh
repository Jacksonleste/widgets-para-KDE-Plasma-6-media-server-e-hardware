#!/bin/sh
echo "Limpando cache de sensores (/dev/shm)..."
rm -f /dev/shm/hwmonitor_static /dev/shm/hwmonitor_state /dev/shm/rm_hw_static_v2 /dev/shm/rm_hw_state

echo "Limpando cache QML do KDE Plasma..."
rm -rf "$HOME/.cache/plasmashell/qmlcache/"* 2>/dev/null || true

echo "Reiniciando o plasmashell para recarregar os widgets..."
systemctl --user restart plasma-plasmashell.service 2>/dev/null || (kquitapp6 plasmashell && kstart plasmashell)
echo "Concluído!"
