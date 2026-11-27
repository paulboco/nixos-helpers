# Sublime Merge Path for Sublime Text (NixOS)

## Short answer

```bash
/etc/profiles/per-user/paulboco/bin/smerge
```

`sublime-merge` is installed via `users.users."paulboco".packages`,  
which links into `/etc/profiles/per-user/paulboco/`.  
Unlike `/nix/store/<hash>/...`, this path survives package updates.

## Steps

1. Confirm the file exists:

```bash
ls -l /etc/profiles/per-user/paulboco/bin/smerge
```

If missing, rebuild, then rerun.

2. Confirm it launches:

```bash
/etc/profiles/per-user/paulboco/bin/smerge
```

3. In Sublime Text, open **Preferences > Settings** and add to the right-hand
(user) pane:

```bash
"sublime_merge_path": "/etc/profiles/per-user/paulboco/bin/smerge"
```

Saved in:

```bash
~/.config/sublime-text/Packages/User/Preferences.sublime-settings
```

4. Restart Sublime Text.

## Troubleshooting

- **Still prompts for a path:**  
    Check JSON syntax and that the setting is in the user pane, not the defaults pane.
- **Broke after an update:**
    You used a `/nix/store/<hash>/...` path.  
    Use the per-user profile path above.
