# NixOS Generation Policy

After pruning, the profile holds 11 plus the two newest.<br>
11 is the oldest of those, so it sits at the bottom of the menu.<br>
The only change to the draft is `baseGen = 11;`.

Save it as `~/nixos/generation-policy.nix`:

```nix
{ pkgs, ... }:

# Goal: the boot menu always shows exactly three entries:
#   1. newest generation (current)
#   2. the generation before it
#   3. a fixed "base" generation that is never removed
#
# NixOS does not do this on its own: configurationLimit only trims boot menu
# entries, and garbage collection only deletes store paths that no generation
# or root references. So we prune generations ourselves, skipping the base.

let
    # Generation number of the base install. Check with:
    #   nix-env -p /nix/var/nix/profiles/system --list-generations
    baseGen = 11;

    # How many of the newest generations to keep besides the base.
    keepNewest = 2;

    # Installs a `prune-generations` command (run it with sudo).
    # It deletes every system generation except:
    #   - the base generation (baseGen)
    #   - the newest `keepNewest` generations by number
    # Deleting a generation removes its link from the profile and the boot
    # menu. Its store paths are freed at the next garbage collection.
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

    # Show at most three entries in the systemd-boot menu: the base plus the
    # two newest, once pruning has run. Right after a rebuild there are
    # briefly four generations, and the base is hidden until you prune.
    boot.loader.systemd-boot.configurationLimit = 3;

    # Weekly garbage collection of unreferenced store paths. The base and
    # kept generations are referenced, so they are safe. This does not
    # remove generations, so pruning is still done by prune-generations.
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

Before you run `prune-generations` for the first time, check that gen 11 is really your base.<br>
Run this on the machine:

```sh
nix-env -p /nix/var/nix/profiles/system --list-generations
```

If it matches, pin it first.<br>
This is the optional extra protection from earlier, and it also guards against a wrong `baseGen`:

```sh
sudo nix-store --add-root /nix/var/nix/gcroots/base-install -r "$(readlink -f /nix/var/nix/profiles/system-11-link)"
```

If gen 11 turns out to be wrong, change `baseGen` and rebuild before pruning.<br>
Pruning deletes the other generations from the menu, though the pin keeps their files.