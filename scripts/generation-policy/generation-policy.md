
After pruning, the profile holds 11 plus the two newest, and 11 is the oldest of those, so it sits at the bottom of the menu. 
The only change to the draft is `baseGen = 11;`.

Save it as `~/nixos/generation-policy.nix`:

```nix
{ pkgs, ... }:

let
    baseGen = 11;
    keepNewest = 2;

    pruneGenerations = pkgs.writeShellScriptBin "prune-generations" ''
        set -euo pipefail
        profile=/nix/var/nix/profiles/system
        gens=$(${pkgs.nix}/bin/nix-env -p "$profile" --list-generations | ${pkgs.gawk}/bin/awk '{print $1}')
        newest=$(echo "$gens" | ${pkgs.coreutils}/bin/tail -n ${toString keepNewest})
        delete=""
        for g in $gens; do
            [ "$g" = "${toString baseGen}" ] && continue
            echo "$newest" | ${pkgs.gnugrep}/bin/grep -qx "$g" && continue
            delete="$delete $g"
        done
        if [ -n "$delete" ]; then
            ${pkgs.nix}/bin/nix-env -p "$profile" --delete-generations $delete
        fi
    '';
in
{
    environment.systemPackages = [ pruneGenerations ];

    boot.loader.systemd-boot.configurationLimit = 3;

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

Before you run `prune-generations` for the first time, check that gen 11 is really your base. Run this on the machine:

```sh
nix-env -p /nix/var/nix/profiles/system --list-generations
```

If it matches, pin it first. This is the optional extra protection from earlier, and it also guards against a wrong `baseGen`:

```sh
sudo nix-store --add-root /nix/var/nix/gcroots/base-install -r "$(readlink -f /nix/var/nix/profiles/system-11-link)"
```

If gen 11 turns out to be wrong, change `baseGen` and rebuild before pruning. Pruning deletes the other generations from the menu, though the pin keeps their files.