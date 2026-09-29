# Documentation

## Troubleshooting

### Service not starting
Check status: `systemctl --user status wayland-spice-clipboard.service`
View logs: `journalctl --user -u wayland-spice-clipboard.service`

### Missing dependencies  
Install: `sudo pacman -S wl-clipboard xclip spice-vdagent`

### SPICE issues
Restart: `sudo systemctl restart spice-vdagentd`

### Works after install, stops after reboot
The bridge writes to the X11 clipboard via Xwayland, which needs `XAUTHORITY` (a per-boot file under `/run/user/<uid>/`). If the service starts before the desktop session imports its environment into `systemd --user`, `xclip` fails with `Authorization required`. Check what the running service actually sees:

```
cat /proc/$(systemctl --user show -p MainPID --value wayland-spice-clipboard.service)/environ | tr '\0' '\n' | grep -E 'DISPLAY|XAUTH'
```

If `XAUTHORITY` is missing, the unit is not bound to the graphical session. It must be `WantedBy=graphical-session.target` (not `default.target`). Re-run `./install.sh` to install the current unit, or fix it by hand:

```
systemctl --user disable --now wayland-spice-clipboard.service
cp systemd/wayland-spice-clipboard.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now wayland-spice-clipboard.service
```

The script now logs `Failed to set X clipboard` (and exits so systemd restarts it) instead of reporting `Synced` when `xclip` fails, so `journalctl --user -u wayland-spice-clipboard.service -b` shows the real state.

### Duplicate spice-vdagent
On Arch the `spice-vdagent` package ships a user unit (`spice-vdagent.service`, part of `graphical-session.target`) that already runs `spice-vdagent -x`. Do not add an XDG autostart entry as well; `pgrep -a spice-vdagent` should show exactly one `spice-vdagent -x` and one `spice-vdagentd -x`.
