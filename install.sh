#!/bin/sh
# Script inicial de instalação dos widgets no KDE Plasma 6
mkdir -p ~/.local/share/plasma/plasmoids
for w in com.jackson.rainmeter.*; do
    ln -sf "$(pwd)/$w" ~/.local/share/plasma/plasmoids/
done
