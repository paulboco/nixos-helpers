# NixOS: Reset to Pristine, Then Rebuild

Goal: return to the initial installation (commit `d0208e6`), then rebuild with the current `~/nixos` config.

- Rollback at any point: `sudo nixos-rebuild switch --rollback`, or pick the previous generation in the boot menu.

## 1. Back up and remove managed dotfiles

- Plasma rewrites these files while it runs and on exit, so it must be logged out before you move them. In order:
    1. Log out of Plasma (application menu → Leave → Log Out). You land on the SDDM login screen.
    2. Press Ctrl+Alt+F3 to reach a text console, then log in as `paulboco`.
    3. Run the command below.
- Move the files to `~/dotfiles-backup`. Nothing is deleted.

    ```bash
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
    ```

- Do not log back in to Plasma yet. If it starts, it recreates these files.
- Stay on the text console for steps 2 to 4. You return to the desktop at step 4, when you reboot.
- If you need the graphical login screen before then, press Ctrl+Alt+F2. On this machine F2 shows the graphical login screen, and F1 is a blank screen with no prompt. Do not log in there until step 4.

## 2. Build the initial commit (safety check)

- Clone and check out the initial commit.

    ```bash
    git clone https://github.com/paulboco/nixos /tmp/nixos-initial && git -C /tmp/nixos-initial checkout d0208e6
    ```

- Build without switching. Nothing on the running system changes.

    ```bash
    sudo nixos-rebuild build -I nixos-config=/tmp/nixos-initial/configuration.nix
    ```

## 3. Switch to the initial commit

- This removes home-manager, your user packages, the Num Lock service, and the boot timeout.

    ```bash
    sudo nixos-rebuild switch -I nixos-config=/tmp/nixos-initial/configuration.nix
    ```

## 4. Reboot and verify

- Reboot.

    ```bash
    sudo reboot
    ```

- After logging in, confirm:
    - Default Plasma theme and wallpaper (not Breeze Dark / green).
    - Dolphin, Kate, and Konsole at default settings.
    - Sublime and Chromium are gone.

## 5. Rebuild with the current configuration

- Run this from a terminal inside the Plasma session, not a text console. `theme.nix` and `wallpaper.nix` need a running plasmashell.
- Use the absolute path. Under `sudo`, `$HOME` may not be your home directory.

    ```bash
    sudo nixos-rebuild switch -I nixos-config=/home/paulboco/nixos/configuration.nix
    ```

- Home-manager will fetch release-26.05 at evaluation time, so the network must be up.
- If the theme or wallpaper did not apply, run the same command again.
- After it finishes, check Dolphin, Kate, mouse, power, and session settings, the Num Lock state, and the `text/plain` default (Sublime).
