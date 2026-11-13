#!/usr/bin/env bash
# Report which packages/tools from the Arch/CachyOS install path are (not) installed.
#
# Sources checked:
#   - pkg_lists/arch_base.txt               (same parsing as pkg_install_arch.sh)
#   - scripts/cachy_os_setup/desktop.sh     (every pacman/paru/yay -S line, flatpak installs)
#   - scripts/cachy_os_setup/housekeeping.sh
#   - manual installs in pkg_install_arch.sh + controller.sh (curl/cargo/npm/git clone)
#
# Usage: scripts/utils/check_installed.sh [-m|--missing-only]
#
# A package counts as installed if pacman considers it satisfied (`pacman -T`), which
# also accepts providers — e.g. wezterm-git satisfies "wezterm".

cd "$(dirname "$0")/../.." || exit 1

MISSING_ONLY=0
[[ "$1" == "-m" || "$1" == "--missing-only" ]] && MISSING_ONLY=1

if [[ -t 1 ]]; then G=$'\e[32m' R=$'\e[31m' Y=$'\e[33m' B=$'\e[1m' N=$'\e[0m'; else G= R= Y= B= N=; fi

AUR_HELPER=$(command -v paru || command -v yay)
declare -a MISSING=()
declare -A SEEN=()

ok()   { (( MISSING_ONLY )) || printf "  ${G}✔${N} %-36s %s\n" "$1" "$2"; }
bad()  { printf "  ${R}✘${N} %-36s %s\n" "$1" "$2"; MISSING+=("$3|$1|$2"); }

# Explain why a missing package might have failed
diagnose() {
    local pkg=$1
    if pacman -Si "$pkg" &>/dev/null; then
        echo "available in $(pacman -Si "$pkg" | awk -F': ' '/^Repository/{print $2; exit}')"
    elif [[ -n $AUR_HELPER ]] && "$AUR_HELPER" -Si --aur "$pkg" &>/dev/null; then
        if [[ -d ~/.cache/paru/clone/$pkg || -d ~/.cache/yay/$pkg ]]; then
            echo "AUR (build was attempted - see cache dir, likely build/check failure)"
        else
            echo "AUR (never built)"
        fi
    else
        echo "NOT FOUND in repos or AUR (typo/renamed?)"
    fi
}

check_pkg() {
    local pkg=$1 src=$2
    [[ -z $pkg || -n ${SEEN[$pkg]} ]] && return
    SEEN[$pkg]=1
    if pacman -T "$pkg" &>/dev/null; then
        if pacman -Qq "$pkg" &>/dev/null; then ok "$pkg" ""; else ok "$pkg" "(satisfied by a provider / group)"; fi
    else
        bad "$pkg" "$(diagnose "$pkg")" "$src"
    fi
}

# Check a non-pacman install. $2 is a shell test expression.
check_cmd() {
    local name=$1 test=$2 src=$3
    if eval "$test" &>/dev/null; then ok "$name" ""; else bad "$name" "manual install" "$src"; fi
}

# Extract package names from `pacman|paru|yay ... -S ...` lines in a script
pkgs_from_script() {
    # join backslash continuations, drop comments, keep install lines
    sed -e ':a' -e '/\\$/N; s/\\\n//; ta' "$1" \
    | sed -E 's/#.*$//' \
    | grep -E '(^|[[:space:];|&])(pacman|paru|yay)[[:space:]].*-S[a-z]*([[:space:]]|$)' \
    | grep -vE -- '-S[a-z]*[iu]|-Si|-Syu' \
    | while read -r line; do
        line=${line#*pacman }; line=${line#*paru }; line=${line#*yay }
        line=${line%%||*}; line=${line%%&&*}
        for tok in $line; do
            [[ $tok == -* || $tok == '$'* ]] && continue
            # expand gst-plugins-{good,bad,ugly}
            eval "printf '%s\n' $tok"
        done
    done
    # package lists installed via `for pkg in a b c; do <pacman|paru> ... "$pkg"`
    sed -nE 's/#.*$//; s/^[[:space:]]*for pkg in (.*);[[:space:]]*do.*/\1/p' "$1" | tr ' ' '\n' | grep -v '^$'
}

section() { printf "\n${B}%s${N}\n" "$1"; }

# ─── arch_base.txt ────────────────────────────────────────────────
section "pkg_lists/arch_base.txt"
while IFS= read -r line; do
    line=${line%%#*}; line=${line//[[:space:]]/}
    [[ -z $line || $line == NOTE* ]] && continue
    check_pkg "$line" "arch_base.txt"
done < pkg_lists/arch_base.txt
for p in git go rustup yay; do check_pkg "$p" "pkg_install_arch.sh"; done

# ─── manual installs (pkg_install_arch.sh / controller.sh) ────────
section "Manual installs (pkg_install_arch.sh, controller.sh)"
check_cmd lazydocker        'command -v lazydocker'                         manual
check_cmd posting           'command -v posting'                            manual
check_cmd lazyssh           'command -v lazyssh'                            manual
check_cmd darya             'command -v darya'                              manual
check_cmd tpm               '[[ -d ~/.tmux/plugins/tpm ]]'                  manual
check_cmd tree-sitter       'command -v tree-sitter'                        manual
check_cmd basalt            'command -v basalt || [[ -x ~/.cargo/bin/basalt ]]' manual
check_cmd x-cmd             '[[ -d ~/.x-cmd.root ]]'                        manual
check_cmd "nvm + node v22"  '[[ -d ~/.nvm/versions/node/v22.17.0 ]]'        manual
check_cmd dcv               'command -v dcv'                                manual
check_cmd yazi-bookmarks    '[[ -d ~/.config/yazi/plugins/bookmarks.yazi ]]' manual
check_cmd neohtop-cli       'npm ls -g neohtop-cli'                         manual
check_cmd tailscale         'command -v tailscale'                          manual
check_cmd oh-my-zsh         '[[ -d ~/.oh-my-zsh ]]'                         manual
check_cmd powerlevel10k     '[[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]' manual
check_cmd docker-service    'systemctl is-enabled docker'                   manual
for p in spotify-player libsixel pavucontrol; do check_pkg "$p" "pkg_install_arch.sh"; done

# ─── CachyOS desktop ──────────────────────────────────────────────
for f in scripts/cachy_os_setup/desktop.sh scripts/cachy_os_setup/housekeeping.sh; do
    [[ -f $f ]] || continue
    section "$f"
    while read -r p; do check_pkg "$p" "$(basename "$f")"; done < <(pkgs_from_script "$f")
done

if command -v flatpak &>/dev/null; then
    section "Flatpak (desktop.sh)"
    for app in org.gtk.Gtk3theme.Adwaita-dark com.usebottles.bottles org.freedesktop.Platform.VulkanLayer.gamescope; do
        check_cmd "$app" "flatpak info $app" flatpak
    done
fi

# ─── Summary ──────────────────────────────────────────────────────
section "Summary"
if (( ${#MISSING[@]} == 0 )); then
    echo "  ${G}Everything is installed.${N}"
else
    echo "  ${R}${#MISSING[@]} missing${N} (some desktop.sh items are optional prompts: gaming/virt/flatpak)"
    printf '%s\n' "${MISSING[@]}" | sort | awk -F'|' '{printf "    %-22s %-34s %s\n", $1, $2, $3}'
fi
