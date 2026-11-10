#!/bin/bash
# Kurulumu kaldırır. Tuşlar, klavye bir sonraki bağlanışında ya da Mac yeniden başlayınca eski haline döner.
set -uo pipefail

LABEL="local.keyboard-remap"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Library/Application Support/KeyboardRemap"

echo "Kaldırıldı."
