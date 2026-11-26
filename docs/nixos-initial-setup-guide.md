# NixOS Initial Setup Guide

## Post-install

1. **Get git** (not installed by default on a fresh minimal system):

    ```bash
    nix-shell -p git
    ```

2. **Clone over HTTPS** (no SSH keys exist yet):

    ```bash
    git clone https://github.com/paulboco/nixos ~/nixos
    ```

3. **Move into the repo:**

    ```bash
    cd ~/nixos
    ```

4. **Replace the hardware config with the new install's.**<br>
    A fresh install means new filesystem UUIDs, so the committed one won't match:

    ```bash
    cp /etc/nixos/hardware-configuration.nix hardware-configuration.nix
    ```

5. **Move the generated config aside and symlink yours:**

    ```bash
    sudo mv /etc/nixos /etc/nixos.bak
    ```

    ```bash
    sudo ln -s ~/nixos /etc/nixos
    ```

6. **Rebuild:**

    ```bash
    sudo nixos-rebuild switch
    ```

7. **Commit the new hardware config** (skip if you don't want per-machine churn in `main`):

    ```bash
    git commit -am "Update hardware config"
    ```

8. **Reboot** to confirm the new generation boots.

## Specific to this config

- **Username:**<br>
    Create your user as `paulboco` during install.<br>
    The config and Home Manager both expect that name.

- **UID 1000:**<br>
    `modules/shared-drive.nix` hardcodes `uid=1000`.<br>
    `paulboco` should get 1000 as the first normal user; check with `id`.

- **Shared drive UUID:**<br>
    `shared-drive.nix` mounts `1DE0-DB30` at `/mnt/shared`.<br>
    It is `nofail`, so a missing drive won't block boot, but it won't mount if the UUID changed.<br>
    Check with `lsblk -f`.

- **Password:**<br>
    The config sets none.<br>
    Run `passwd paulboco` if the installer didn't set one.

- **`stateVersion`:**<br>
    Leave both `"26.05"` values alone.<br>
    If the installed NixOS release differs from 26.05, check that Home Manager's `release-26.05` still matches your nixpkgs.

- **Home Manager conflicts:**<br>
    `backupFileExtension = "backup"` renames existing dotfiles (e.g. KDE configs from a Calamares install) to `*.backup` instead of failing the rebuild.

- **Fetch failure:**<br>
    If the rebuild fails on `fetchTarball`, it's a network problem.<br>
    Fix the connection and rerun.
