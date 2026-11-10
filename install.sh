#!/bin/bash
# İzleyiciyi derler ve Mac açılışında başlayacak şekilde kurar. Tekrar çalıştırılırsa mevcut kurulumu günceller.
set -euo pipefail

LABEL="local.keyboard-remap"
DIR="$HOME/Library/Application Support/KeyboardRemap"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/keyboard-remap.log"
SRC="$(cd "$(dirname "$0")" && pwd)/keyboard-remap.swift"
DOMAIN="gui/$(id -u)"

mkdir -p "$DIR" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
swiftc -O "$SRC" -o "$DIR/keyboard-remap"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DIR/keyboard-remap</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG</string>
    <key>StandardErrorPath</key>
    <string>$LOG</string>
</dict>
</plist>
EOF
plutil -lint -s "$PLIST"

# Önceki kurulum yüklüyse kaldırılmasını bekle; yoksa bootstrap "Input/output error" verebilir.
if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
    launchctl bootout "$DOMAIN/$LABEL"
    while launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; do sleep 0.2; done
fi
launchctl bootstrap "$DOMAIN" "$PLIST"

echo "Kuruldu. Kayıtlar: $LOG"
