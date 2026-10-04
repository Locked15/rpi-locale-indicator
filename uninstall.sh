#!/usr/bin/env bash
# Remove the indicator. Restores the backed-up panel config if install.sh made one.
set -u
pkill -f '^python3 .*/kbd-indicator' 2>/dev/null
rm -f "$HOME/.local/bin/kbd-indicator" "$HOME/.config/autostart/kbd-indicator.desktop"
panel="$HOME/.config/lxpanel-pi/panels/panel"
if [ -f "$panel.bak" ]; then mv -f "$panel.bak" "$panel"; else rm -f "$panel"; fi
echo "Removed. Keyboard layout settings are left untouched."
