#!/bin/bash
set -e

echo "Installing Wayland SPICE clipboard fix..."

if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    echo "Warning: Not running on Wayland session"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Installing dependencies..."
sudo pacman -S wl-clipboard xclip spice-vdagent

echo "Installing bridge script..."
sudo cp scripts/wayland-spice-clipboard /usr/local/bin/
sudo chmod +x /usr/local/bin/wayland-spice-clipboard

echo "Setting up service..."
mkdir -p ~/.config/systemd/user
# Drop any enable symlink from a previous install (the unit used to be
# WantedBy=default.target; it is now WantedBy=graphical-session.target).
systemctl --user disable --now wayland-spice-clipboard.service 2>/dev/null || true
cp systemd/wayland-spice-clipboard.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now wayland-spice-clipboard.service

echo "Setting up spice agent..."
if [ -f /usr/lib/systemd/user/spice-vdagent.service ]; then
    # The distro package already starts spice-vdagent -x as part of
    # graphical-session.target. A second copy via XDG autostart would fight
    # over the same vdagentd socket, so make sure none is left behind.
    echo "Distro provides spice-vdagent.service user unit; skipping XDG autostart entry"
    rm -f ~/.config/autostart/spice-vdagent-manual.desktop
else
    ./scripts/setup-spice-autostart.sh
fi

# spice-vdagentd is a static unit pulled in by udev/socket activation; just
# make sure it is running now.
sudo systemctl start spice-vdagentd.socket spice-vdagentd

echo "Installation complete!"
echo "Check status: systemctl --user status wayland-spice-clipboard.service"
echo "Monitor logs: journalctl --user -u wayland-spice-clipboard.service -f"
