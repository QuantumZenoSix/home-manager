---
name: update-command-finder
description: Syncs pkg_lists/cmd_list.txt (the data file read by the `cf` command finder in dotfiles/.zshrc) with the custom shell functions and aliases defined in dotfiles/.bash_aliases, .bash_wrappers, .bash_utils and .zsh_customizations. Use when the user adds, removes, or renames a bash/zsh function or alias, or asks to update, refresh, sync, or audit cmd_list.txt / the command finder / `cf`.
argument-hint: "[function name or 'full' resync]"
---

# Update Command Finder

Keep the `BSH` rows of `pkg_lists/cmd_list.txt` **true to the shell files**. The functions in `dotfiles/` are the source of truth. Describe each one from its real body, never from its name alone.

## File format

```
TYPE | GROUP | name | description
```

- `TYPE`: `BSH` (the user's functions/aliases) or `CMD` (installed packages). This skill covers `BSH`. Only touch `CMD` rows if the user asks (the `cli-tools-docs` skill covers packages).
- `GROUP`: one of the existing headings (`Git`, `Docker`, `Nix & Home Manager`, `Neovim`, `Niri & desktop`, `Shell & prompt`, `SSH & networking`, `System & hardware`, `Audio & video`, `Text & documents`, `Files, search & sync`, `Dev & AI`, `WSL`). Reuse one before inventing a new group. `cf` shows groups in the order they first appear in the file.
- `cf` splits on `|` with awk, so **never put a literal `|` in a description**.
- Blank lines and `#` lines are ignored.

## Sources

| File | Holds |
| --- | --- |
| `dotfiles/.bash_aliases` | Short aliases and tiny functions (`y`, `l`, `r`, `f`, `lg`…) |
| `dotfiles/.bash_wrappers` | Workflow functions: `gt_*`, `nx_*`, `dk_*`, `nv_*`, `nr_*`, `ps1_*` |
| `dotfiles/.bash_utils` | Helpers: `ut_txt_*`, `ut_sys_*`, `ut_ssh_*`, `ut_wsl_*`, `ut_o_*`, `ut_ufw_*` |
| `dotfiles/.zsh_customizations` | A few aliases (e.g. `ch`), plus internal zsh hooks |

`git log --oneline -15 -- dotfiles/.bash_aliases dotfiles/.bash_wrappers dotfiles/.bash_utils` shows what changed recently.

## Find the drift

From the repo root:

```bash
comm -3 \
  <(grep -hoE '^\s*(function\s+)?[A-Za-z_][A-Za-z0-9_-]*\s*\(\)|^\s*alias\s+[A-Za-z_][A-Za-z0-9_-]*=' \
      dotfiles/.bash_aliases dotfiles/.bash_wrappers dotfiles/.bash_utils dotfiles/.zsh_customizations \
    | sed -E 's/^\s*(function\s+|alias\s+)?//; s/\s*(\(\)|=)$//' | sort -u) \
  <(awk -F' *[|] *' '$1=="BSH"{print $3}' pkg_lists/cmd_list.txt | sort -u)
```

- **Left column**: defined but not listed. These are candidates to add.
- **Indented right column**: listed but no longer defined. Check for a rename, then remove or rename the row.

The name pattern allows hyphens (e.g. `ut_o_toggle-wifi-ipv6`). Read each candidate's body (`grep -n 'name' dotfiles/.bash*`, then read that part of the file).

### Expected noise (don't add these)

- Internal helpers and zsh hooks: `auto_*`, `configure_ohmyzsh`, `enable_*` prompt helpers, `command_finder` / `command_finder_beta` (`cf_beta` is the listed entry point).
- Plain shell defaults: `grep`, `egrep`, `fgrep`, `mkdir`, `..`-style cd aliases.
- Short aliases for a listed function (`diffy`, `mv_conflicts`, `taildrop_to_phone`, `ollama_webui`, `openvpn`, `gg`, `nv`, `ds`). Mention them in the main row's description, e.g. `(alias \`openvpn\`)` or `(also \`gg\`)`, instead of giving them their own row. Only add one if the user asks.
- Anything commented out.

## Writing rows

- One sentence that says what it actually does, ending with a period, matching the tone of the existing rows. Note required arguments or modes (e.g. "`off` disconnects").
- Prefix aliases with `(alias)` when the name is an alias, not a function.
- Put the row in the group that fits its purpose, not its prefix (e.g. `ut_sys_set_ufw_rules` goes under `SSH & networking`). Keep rows **alphabetical by name** within the group.
- Don't include personal paths, usernames, or VPN profile names in descriptions.

## Finish

Tell the user which rows you added, renamed, or removed, plus any defined names you skipped on purpose (aliases, internals), so they can ask for them. Don't commit unless asked.
