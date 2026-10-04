#!/usr/bin/env bash
# Install the keyboard layout tray indicator for the current user.
#   ./install.sh            indicator + autostart + move panel tray next to clock
#   ./install.sh --system   additionally set us,ru + Alt+Shift in /etc/default/keyboard (sudo)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

install -Dm755 "$here/bin/kbd-indicator" "$HOME/.local/bin/kbd-indicator"
install -Dm644 "$here/autostart/kbd-indicator.desktop" "$HOME/.config/autostart/kbd-indicator.desktop"

# Per-user lxpanel-pi config: system config with the tray plugin moved right
# before the clock. Existing user config is backed up once.
sys_panel="${SYS_PANEL:-/etc/xdg/lxpanel-pi/panels/panel}"
user_panel="$HOME/.config/lxpanel-pi/panels/panel"
if [ -f "$sys_panel" ]; then
    mkdir -p "$(dirname "$user_panel")"
    [ -f "$user_panel" ] && [ ! -f "$user_panel.bak" ] && cp "$user_panel" "$user_panel.bak"
    python3 - "$sys_panel" "$user_panel" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
i = src.index("Plugin {")
head, body = src[:i], src[i:]
blocks = re.findall(r"Plugin \{\n.*?\n\}\n", body, re.S)
assert "".join(blocks) == body, "unexpected panel config format"
tray = next(b for b in blocks if "type=tray" in b)
blocks.remove(tray)
clock = next(n for n, b in enumerate(blocks) if "type=clock" in b)
blocks.insert(clock, tray)
open(sys.argv[2], "w").write(head + "".join(blocks))
PY
    echo "panel: tray moved before clock ($user_panel)"
else
    echo "panel: $sys_panel not found, skipped"
fi

if [ "${1:-}" = "--system" ]; then
    sudo sed -i \
        -e 's/^XKBLAYOUT=.*/XKBLAYOUT="us,ru"/' \
        -e 's/^XKBOPTIONS=.*/XKBOPTIONS="compose:ralt,terminate:ctrl_alt_bksp,grp:alt_shift_toggle"/' \
        /etc/default/keyboard
    echo "system: /etc/default/keyboard updated"
fi

echo "Done. Log out and in again (or run: lxpanelctl-pi restart; kbd-indicator &)."
