# rpi-locale-indicator

A small keyboard-layout indicator for the Raspberry Pi OS (Debian 13 "trixie")
`lxpanel-pi` panel. It shows the active layout (`US` / `RU`) in the panel, next
to the clock, and switches layout on click.

Developed and tested on a Raspberry Pi 5B running a desktop session over xrdp
(Xorg + openbox + `lxpanel-pi`).

## Contents

| Path | Purpose |
| --- | --- |
| `bin/kbd-indicator` | The indicator (Python 3, GTK 3, ctypes XKB/Xlib). |
| `autostart/kbd-indicator.desktop` | XDG autostart entry (LXDE sessions only). |
| `config/etc-default-keyboard` | Reference `/etc/default/keyboard` (`us,ru`, Alt+Shift). |
| `config/labwc-environment` | Reference `~/.config/labwc/environment` (same layout for a labwc/Wayland session). |
| `install.sh` / `uninstall.sh` | User-level install and removal. |

## Keyboard layout setup

The indicator only displays and toggles the XKB group; the layouts themselves
come from the system keyboard configuration:

```
XKBLAYOUT="us,ru"
XKBOPTIONS="compose:ralt,terminate:ctrl_alt_bksp,grp:alt_shift_toggle"
```

`./install.sh --system` writes this into `/etc/default/keyboard` (uses `sudo`).
To apply it to a running X session without logging out:

```
setxkbmap -layout us,ru -option "" -option compose:ralt,terminate:ctrl_alt_bksp,grp:alt_shift_toggle
```

On a labwc (Wayland) session the equivalent is `XKB_DEFAULT_LAYOUT` and
`XKB_DEFAULT_OPTIONS` in `~/.config/labwc/environment`; see
`config/labwc-environment`. Note that the indicator itself needs an X11
system tray, so it is meant for the X11/xrdp session.

## Install

```
./install.sh            # indicator, autostart, panel tray placement
./install.sh --system   # additionally configure /etc/default/keyboard
```

Then log out and back in, or restart the panel and start the indicator by hand:

```
lxpanelctl-pi restart
kbd-indicator &
```

`install.sh` copies the script to `~/.local/bin`, the autostart entry to
`~/.config/autostart`, and writes `~/.config/lxpanel-pi/panels/panel`: the
system panel config with the `tray` plugin moved directly before `clock`. An
existing user panel config is backed up once as `panel.bak`.

## Uninstall

```
./uninstall.sh
```

Stops the indicator, removes the files above and restores the panel config.
Keyboard layout settings are not touched.

## How it works

- **Docking.** The script creates a `GtkPlug` containing a flat `GtkButton` and
  asks the panel's system tray manager (`_NET_SYSTEM_TRAY_S0`) to dock it via
  the XEmbed `SYSTEM_TRAY_REQUEST_DOCK` message. This, rather than
  `GtkStatusIcon`, gives a native-looking hover highlight and the system UI
  font.
- **State.** The active layout is polled every 300 ms with `XkbGetState`.
  Clicking calls `XkbLockGroup` to select the next group.
- **Position.** `lxpanel-pi` has no layout plugin and only one tray. Moving the
  `tray` plugin next to the clock puts the indicator there; native plugins
  (Bluetooth, Wi-Fi, ...) are unaffected because they are not tray icons.
- **Theme.** Colours come from the GTK theme (`@theme_bg_color`,
  `@theme_fg_color`), so light and dark themes are both handled.
- **Optional by design.** The whole script is wrapped so any failure (no
  display, no tray, missing GTK) ends in a silent `exit 0`. The autostart
  command also ends in `|| true`. A broken indicator never affects the session.

## Limitations

- The layout names are hardcoded to `US` and `RU` (`names` in the script).
  Add entries there for more layouts.
- If the panel restarts, the indicator exits and is not re-docked until the
  next login.
- The theme background (`#f8f8fa` in the default light theme) can differ very
  slightly from the panel background.
- If xrdp applies the RDP client's keyboard layout on connect, the group list
  may be replaced; re-run the `setxkbmap` command above.
- Only `lxpanel-pi` was tested.
