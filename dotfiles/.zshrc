# ────────────────────────────────────────────────
# PATH UPDATES
# ────────────────────────────────────────────────

# export MANPATH="/usr/local/man:$MANPATH"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Add $HOME/bin if it hasn't been already added
[[ ":$PATH:" == *":$HOME/bin:"* ]] || PATH="$PATH:$HOME/bin"

# Add $HOME/.local/bin if it hasn't been already added
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || PATH="$PATH:$HOME/.local/bin"

# Add path for go installs
export PATH="$PATH:$HOME/go/bin"

# Add path for cargo installs
export PATH="$PATH:$HOME/.cargo/bin"

# Add /usr/local/go/bin to PATH in case you have a later version here
export PATH=/usr/local/go/bin:$PATH

# Add /opt/Applications/ to $PATH
export PATH=/opt/Applications/:$PATH

# Add .local/bin to PATH
export PATH="$HOME/.local/bin":$PATH
export PATH="$HOME/.local/lib":$PATH

# NVIM to use binary PATH in /opt if it exists there
if [[ -s /opt/nvim-linux64/bin/nvim && ! -s /usr/local/bin/nvim ]]; then
    export PATH="/opt/nvim-linux64/bin":$PATH
elif [[ -s /opt/nvim-linux-x86_64/bin/nvim && ! -s /usr/local/bin/nvim ]]; then
    export PATH="/opt/nvim-linux-x86_64/bin":$PATH
elif [[ -s /usr/local/bin/nvim ]]; then
    export PATH="/usr/local/bin":$PATH
fi

# Go to use binary PATH in /usr/local/bin if it exists there
if [[ -s /usr/local/bin/go ]]; then
    alias go="/usr/local/bin/go"
fi

# Tmux to use binary PATH in /usr/local/bin if it exists there
if [[ -s /usr/local/bin/tmux ]]; then
    alias tmux="/usr/local/bin/tmux -2"
fi

##### Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/bobby_vz/sandbox/google-cloud-sdk/path.zsh.inc' ]; then . '/home/bobby_vz/sandbox/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/bobby_vz/sandbox/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/bobby_vz/sandbox/google-cloud-sdk/completion.zsh.inc'; fi



# ────────────────────────────────────────────────
# SHELL VARIABLE UPDATES
# ────────────────────────────────────────────────

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
else
    export EDITOR='vim'
  export EDITOR='nvim'
fi

# SET CUSTOM MANPAGER APP
export MANPAGER='vim +MANPAGER -'

# Set base for posting
export POSTING_ROOT=/home/bobby/posting/
export POSTING_EDITOR=vim

# LOAD ANY SAVED KEYS
# > Claude
if [[ -s $HOME/.claude/.credentials.json ]]; then
    CLAUDE_TOKEN=$(jq '.[] | .accessToken' $HOME/.claude/.credentials.json 2> /dev/null )
    if [[ ! -z "${CLAUDE_TOKEN}" ]]; then
        export ANTHROPIC_API_KEY=${CLAUDE_TOKEN//\"/}
    fi
fi


# This ensures that tmux always starts with 256-color support - good for vim/neovim
alias tmux="tmux -2"
# export TERM=screen-256color
# Works better with vim
export TERM=xterm-256color

# NODE VERSION MANAGER
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s /usr/share/nvm/init-nvm.sh ] && \. /usr/share/nvm/init-nvm.sh  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# X-CMD (provides the `x` function + `x-cmd`). Its installer can't add this itself
# because ~/.zshrc is a read-only Home Manager symlink.
[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X"


# ────────────────────────────────────────────────
# LOAD PROMPT AND SHELL ENVIRONMENT
# ────────────────────────────────────────────────

# 1, Load functions to handle prompt/shell env loadouts
[[ -s ~/.zsh_customizations ]] && source ~/.zsh_customizations

# 2. Set prompt (needs to run before shell environment)
if [[ $BLASTOFF == 1 ]]; then
    enable_starship_prompt
elif [[ $POSHY == 1 ]]; then
    enable_ohmyposh
else
    enable_powerline_prompt
fi


# 3. Enable Shell Environment (ohmyzsh)
configure_ohmyzsh


# ────────────────────────────────────────────────
# LOAD CONF/ENV FILES
# ────────────────────────────────────────────────
# Runs after shell env loads

# Force other bash files to load
[[ -s ~/.creds.env ]] && source ~/.creds.env
[[ -s ~/.bash_aliases ]] && source ~/.bash_aliases
[[ -s ~/.bash_wrappers ]] && source ~/.bash_wrappers
[[ -s ~/.bash_utils ]] && source ~/.bash_utils
# [[ -s ~/.bash_git ]] && source ~/.bash_git
# [[ -s ~/.oh-my-zsh/oh-my-zsh.sh ]] && source ~/.oh-my-zsh/oh-my-zsh.sh




# ────────────────────────────────────────────────
# NIX PKG MANAGER BIN PATH
# ────────────────────────────────────────────────
# Nix bin paths should not preceed the default pkg manager's location of a pkg
# This needs to stay near the bottom to ensure PATH has latest updates and I can append nix path 
export PATH="$PATH:${HOME}/.nix-profile/bin"


# ────────────────────────────────────────────────
# GUI THEMING (commenting out for now - added to niri config)
# ────────────────────────────────────────────────
# export QT_QPA_PLATFORMTHEME=qt6ct
# export QT_STYLE_OVERRIDE=kvantum

# ────────────────────────────────────────────────
# Custom commands for finding my core things
# ────────────────────────────────────────────────
# Keep this at the end - this is a function that lets you fuzzy-find all my custom functions

# Command finder (cf) | find my custom bash functions/aliases or installed packages
#   cf      -> asks which category, then fuzzy-find it grouped by use
#   cf f    -> my functions & aliases (BSH entries)   [Enter at the prompt = f]
#   cf p    -> packages & tools (CMD entries)
#   cf a    -> everything
# Entries + groups live in pkg_lists/cmd_list.txt  (TYPE | GROUP | name | description)
command_finder(){
    local cmd_list=~/.config/home-manager/pkg_lists/cmd_list.txt
    local choice=$1 type title sel

    if [[ -z $choice ]]; then
        print -nP "%BLooking for:%b  %F{green}[f]%f my functions/aliases   %F{cyan}[p]%f packages/tools   %F{yellow}[a]%f all  "
        read -k 1 choice || return
        print
    fi

    case $choice in
        f|b|$'\n') type=BSH; title="Functions & aliases" ;;
        p|c)       type=CMD; title="Packages & tools" ;;
        a)         type=ALL; title="Everything" ;;
        *)         return 0 ;;
    esac

    # Each fzf line is "name<TAB>display". Group header lines have an empty name,
    # so selecting one does nothing. Groups keep the order they appear in the file.
    sel=$(awk -F' *[|] *' -v want="$type" '
        /^[[:space:]]*(#|$)/ { next }
        want != "ALL" && $1 != want { next }
        {
            key = $1 SUBSEP $2
            if (!(key in cnt)) order[++ng] = key
            n = ++cnt[key]
            name[key, n] = $3; desc[key, n] = $4
            if (length($3) > w) w = length($3)
        }
        END {
            fmt = "%s\t   \033[%sm%-" w "s\033[0m  %s  \033[2m[%s]\033[0m\n"
            for (g = 1; g <= ng; g++) {
                key = order[g]; split(key, kp, SUBSEP)
                label = kp[2]
                if (want == "ALL") label = label (kp[1] == "BSH" ? " · functions" : " · packages")
                color = (kp[1] == "BSH") ? "32" : "36"
                printf "\t\033[1;33m── %s ──\033[0m\n", label
                for (i = 1; i <= cnt[key]; i++)
                    printf fmt, name[key, i], color, name[key, i], desc[key, i], kp[2]
            }
        }' "$cmd_list" |
        fzf --ansi --no-sort --layout=reverse --height=80% \
            --delimiter=$'\t' --with-nth=2 \
            --prompt="$title > " \
            --header="Enter: run   Esc: cancel   (typing a group name filters to that group)" |
        cut -f1)

    [[ -z $sel ]] && return 0
    print -s -- "$sel"   # add to history so up-arrow can re-run / edit it with args
    eval "$sel"          # eval (not $(...)) so aliases like gt_show_merges work too
}
alias cf="command_finder "

# Tui finder (tf) | reads a list of my fav tui apps and allows me to find them by brief description.
tui_finder(){

    TUI_FILE=~/.config/home-manager/pkg_lists/tui_list.txt
    eval $(awk '{print $1}'  $TUI_FILE | sort -r | fzf --preview="awk '/^{}/ {print \$0}' $TUI_FILE " --preview-window='right:75%')

}
alias tf="tui_finder "











# Mount SSHFS dirs as needed
# SSHFS_MOUNT_COUNT=$(ps aux | grep -i sftp | grep -v grep | wc -l )
# [[ ${SSHFS_MOUNT_COUNT} -eq 0 ]] && sudo sshfs alpha:/home/control-io/ /home/bobby/alpha -oIdentityFile=/home/bobby/.ssh/pbx-pems/<key>.pem


# Load other bash files if not loaded
#[[ ${ALIASES_LOADED} -ne 1 && -s ~/.bash_aliases ]] && source ~/.bash_aliases
#[[ ${PBX_LOADED} -ne 1 && -s ~/.bash_pbx ]] && source ~/.bash_pbx
#[[ ${GIT_LOADED} -ne 1 && -s ~/.bash_git ]] && source ~/.bash_git
#[[ ${UTILS_LOADED} -ne 1 && -s ~/.bash_utils ]] && source ~/.bash_utils


# eval $(declare -f | grep 'ut_' | awk '{print $1}' | fzf)


