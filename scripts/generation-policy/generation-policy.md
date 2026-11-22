# NixOS Generation Policy

## File `~/nixos/generation-policy.nix`:

```nix
{ pkgs, ... }:

# Goal: the boot menu always shows exactly three entries:
#     1. Newest generation (current)
#     2. The generation before it
#     3. A fixed "base" generation that is never removed
#
# NixOS does not do this on its own:
#     - `configurationLimit` only trims boot menu entries.
#       It hides the older generations from the menu, but they still exist
#       in the profile and keep their store paths alive until deleted.
#     - garbage collection only deletes store paths that no generation or root references
#
# So we prune generations ourselves, skipping the base.
#
# Usage:
#     From the fourth generation on, run `sudo prune-generations` after a rebuild.
#
# Optional extra pin of the base (it is already protected while it is in the profile):
#     sudo nix-store --add-root /nix/var/nix/gcroots/base-install \
#         -r "$(readlink -f /nix/var/nix/profiles/system-1-link)"

let
    # Generation number of the base install.
    # This is a clean install, so the base is generation 1.
    # Check with:
    #     `nix-env -p /nix/var/nix/profiles/system --list-generations`
    baseGen = 1;

    # How many of the newest generations to keep besides the base.
    keepNewest = 2;

    # Installs a `prune-generations` command (run it with sudo).
    #
    # It deletes every system generation except:
    #     - the base generation (baseGen)
    #     - the newest `keepNewest` generations by number
    #
    # Deleting a generation removes its link from the profile and the boot menu.
    # Its store paths are freed at the next garbage collection.
    pruneGenerations = pkgs.writeShellScriptBin "prune-generations" ''
        set -euo pipefail

        # The system profile; every generation is a link inside it.
        profile=/nix/var/nix/profiles/system

        # List of generation numbers, oldest first.
        gens=$(${pkgs.nix}/bin/nix-env -p "$profile" --list-generations | ${pkgs.gawk}/bin/awk '{print $1}')

        # The newest generations to keep (last N lines of the list).
        newest=$(echo "$gens" | ${pkgs.coreutils}/bin/tail -n ${toString keepNewest})

        # Build the list of generations to delete: everything that is
        # neither the base nor one of the newest.
        delete=""
        for g in $gens; do
            [ "$g" = "${toString baseGen}" ] && continue
            echo "$newest" | ${pkgs.gnugrep}/bin/grep -qx "$g" && continue
            delete="$delete $g"
        done

        # Delete them, if there is anything to delete.
        if [ -n "$delete" ]; then
            ${pkgs.nix}/bin/nix-env -p "$profile" --delete-generations $delete
        fi
    '';
in
{
    # Make the prune-generations command available system-wide.
    environment.systemPackages = [ pruneGenerations ];

    # Show at most three entries in the systemd-boot menu:
    #     - The base plus the two newest once pruning has run
    #     - Right after a rebuild there are briefly four generations
    #     - The base is hidden until you prune
    boot.loader.systemd-boot.configurationLimit = 3;

    # Weekly garbage collection of unreferenced store paths.
    # The base and kept generations are referenced, so they are safe.
    # This does not remove generations, so pruning is still done by prune-generations.
    nix.gc = {
        automatic = true;
        dates = "weekly";
    };
}
```

Then add it to the `imports` list in your main config:

```nix
imports = [ ./generation-policy.nix ];
```

This is a clean install, so generation 1 is your base and `baseGen = 1` is already set.<br>
To confirm, run this on the machine:

```sh
nix-env -p /nix/var/nix/profiles/system --list-generations
```

It should list only generation 1.<br>
Optionally, pin it as extra protection:

```sh
sudo nix-store --add-root /nix/var/nix/gcroots/base-install -r "$(readlink -f /nix/var/nix/profiles/system-1-link)"
```

There is nothing to prune yet.<br>
As you rebuild, the menu fills out to base, previous, and current.<br>
From the fourth generation on, run `sudo prune-generations` after a rebuild to keep it at three.
