# ------------------------------------------------------------------------------
# 1. Back up and remove managed dotfiles
# ------------------------------------------------------------------------------

# Move dotfiles to ~/dotfiles-backup.
cd ~ && for f in \
    .config/dolphinrc \
    .config/katerc \
    .config/kcminputrc \
    .config/powerdevilrc \
    .config/ksmserverrc \
    .config/mimeapps.list \
    .config/kdeglobals \
    .config/plasma-org.kde.plasma.desktop-appletsrc \
    .local/share/kxmlgui5/dolphin/dolphinui.rc \
    .local/share/kxmlgui5/konsole/sessionui.rc
do
    if [ -e "$f" ] || [ -L "$f" ]; then
        mkdir -p "$HOME/dotfiles-backup/$(dirname "$f")"
        mv -v "$f" "$HOME/dotfiles-backup/$f"
    fi
done

# ------------------------------------------------------------------------------
# 2. Build the initial commit
# ------------------------------------------------------------------------------

# Clone and check out the initial commit
git clone https://github.com/paulboco/nixos /tmp/nixos-initial && git -C /tmp/nixos-initial checkout d0208e6

# Build without switching.
sudo nixos-rebuild build -I nixos-config=/tmp/nixos-initial/configuration.nix

# ------------------------------------------------------------------------------
# 3. Switch to the initial commit
# ------------------------------------------------------------------------------

# This removes home-manager, your user packages, the Num Lock service, and the boot timeout.
sudo nixos-rebuild switch -I nixos-config=/tmp/nixos-initial/configuration.nix

# ------------------------------------------------------------------------------
# 4. Reboot and verify
# ------------------------------------------------------------------------------

#Reboot.
sudo reboot
