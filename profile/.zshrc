# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/powerlevel10k/powerlevel10k.zsh-theme
source /home/shared/pyenv/bin/activate

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# -------------------------------------------------------------
# Fix ZSH Session History Mixing
# -------------------------------------------------------------
SAVEHIST=1000  # Save most-recent 1000 lines
HISTFILE=~/.zsh_history
# Disable active sharing and real-time appending between terminals
unsetopt share_history
unsetopt inc_append_history
# Enable local memory tracking and safe appending on close
setopt append_history

if [[ -d "$HOME/bin" ]]; then
    PATH="$HOME/go/bin:$HOME/bin:/home/shared/apps/JetBrains/Toolbox/scripts:$PATH"
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/kira/.cache/lm-studio/bin"
export OLLAMA_API_KEY="ollama"
export OLLAMA_BASE_URL="http://localhost:11434/v1"

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
[[ -f /home/kira/git/devopsnextgenx/gnome-extensions/gui-react-ollama/node_modules/tabtab/.completions/electron-forge.zsh ]] && . /home/kira/git/devopsnextgenx/gnome-extensions/gui-react-ollama/node_modules/tabtab/.completions/electron-forge.zsh
# Shell-GPT integration ZSH v0.2
_sgpt_zsh() {
if [[ -n "$BUFFER" ]]; then
    _sgpt_prev_cmd=$BUFFER
    BUFFER+="⌛"
    zle -I && zle redisplay
    BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd" --no-interaction)
    zle end-of-line
fi
}
zle -N _sgpt_zsh
bindkey ^l _sgpt_zsh
# Shell-GPT integration ZSH v0.2
alias ls="logo-ls"
export OLLAMA_BASE_URL=http://localhost:11434
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
askx() {
  [ -z "$1" ] && { echo "Error: Missing prompt"; return 1; }
  ask "$1" -c | bash
}

. "$HOME/.local/bin/env"
alias zdocker="docker --context zbox"
alias dups="find . -type f -name '*(1).jpg' |cut -d "/" -f 2,3|grep -v jpg|uniq -c |sort"
alias xacts="cd /media/data/xos/actresses"
alias movies="cd /media/zbox/storage/ShareMe/media/movies"
alias serials="cd /media/zbox/Crucial-X6/ShareMe/media/serials"
alias songs="cd /media/zbox/Crucial-X6/ShareMe/media/songs/target"
alias nt="nautilus"
alias download="~/bin/download.sh"
alias xserials="cd /media/zbox/Crucial-X6/ShareMe/media/serials"
alias chat-mn='llama-cli -m \"/home/shared/lmstudio/.lmstudio/models/mradermacher/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated-i1-GGUF/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated.i1-Q4_K_S.gguf\" -cnv'
ddups() {
rm "$1"/*"(1)"*
}

ldups() {
ls "$1"/*"(1)"*
}

# Added by LM Studio CLI tool (lms)
export PATH="$PATH:/home/kira/.lmstudio/bin"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# alias chat-server='~/bin/llama-turbo-server -m "/home/shared/lmstudio/.lmstudio/models/mradermacher/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated-i1-GGUF/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated.i1-Q4_K_S.gguf" --port 8080 --host 0.0.0.0'
alias chat-server='~/bin/llama-turbo-server -m "/home/shared/lmstudio/.lmstudio/models/mradermacher/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated-i1-GGUF/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated.i1-Q4_K_S.gguf" --port 8080 --host 0.0.0.0 -ngl 12 --flash-attn on -c 16384 --cache-type-k turbo3 --cache-type-v turbo3 --ubatch-size 128 -n 8192'
alias novel-server='~/bin/llama-turbo-server -m "/home/shared/lmstudio/.lmstudio/models/mradermacher/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated-i1-GGUF/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated.i1-Q4_K_S.gguf" --port 8080 --host 0.0.0.0 -ngl 12 --flash-attn on -c 32768 --cache-type-k turbo3 --cache-type-v turbo3 -n 12000 --ignore-eos --repeat-penalty 1.17 --metrics'
alias lexi-server='~/bin/llama-turbo-server -m "/home/shared/lmstudio/.lmstudio/models/bartowski/Llama-3.1-8B-Lexi-Uncensored-V2-GGUF/Llama-3.1-8B-Lexi-Uncensored-V2-Q2_K_L.gguf" --port 8080 --host 0.0.0.0 -ngl 12 --flash-attn on -c 32768 --cache-type-k turbo3 --cache-type-v turbo3 -n 12000 --ignore-eos --repeat-penalty 1.17 --metrics'
alias zbox='ssh admn@192.168.12.111'

# opencode
export PATH=/home/kira/.opencode/bin:$PATH
alias zsim='sudo /opt/simulator/simulator --no-sandbox'


# Shell-GPT integration ZSH v0.2
_sgpt_zsh() {
if [[ -n "$BUFFER" ]]; then
    _sgpt_prev_cmd=$BUFFER
    BUFFER+="⌛"
    zle -I && zle redisplay
    BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd" --no-interaction)
    zle end-of-line
fi
}
zle -N _sgpt_zsh
bindkey ^l _sgpt_zsh
# Shell-GPT integration ZSH v0.2
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="/home/kira/.nvm/versions/node/v24.0.1/bin:$PATH"
export PATH="/home/kira/.nvm/versions/node/v24.0.1/bin:$PATH"

command_not_found_handler() {
    if (( $+commands[$1.sh] )); then
        local cmd="$1.sh"
        shift
        exec "$cmd" "$@"
    fi
    echo "zsh: command not found: $1" >&2
    return 127
}

export DEVCONTAINER_MOUNT_PATH=/usr/local

export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$HOME/.dotnet
alias zbox="ssh admn@zbox.local"
alias minis="ssh admn@minis.local"

mkmv() {
  mkdir -p "$1" && mv "$1".* "$1/" && ls -ltr "$1"
}

prepage() {
    for ((i=2; i<=$1; i++)); do
        cp page_1.yml "page_$i.yml"
    done
}

alias bat="batcat --theme=Dracula "
batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 batcat --diff
}

alias nats-logs="journalctl --user -u nats-download-service -f"
alias bat="batcat --theme=Dracula "

gifify() {
    local input="$1"
    local scale="${2:-720}"
    local fps="${3:-5}"
    
    if [ -z "$input" ]; then
        echo "Usage: gifify <input_file> [scale_width] [fps]"
        return 1
    fi

    local output="${input%.*}.gif"
    ffmpeg -i "$input" -vf "fps=$fps,scale=$scale:-1:flags=lanczos" "$output"
}

# Show top storage consumers up to 5 directory levels
# du5 - colored, side-by-side, concurrent storage report (works in bash AND zsh)
# Add to ~/.bashrc or ~/.zshrc (or: source du5.sh)
#
# Body is wrapped in ( ... ) so it runs in a subshell: no "[1] 1234" job
# noise, and temp files are cleaned up on exit / Ctrl-C.

du5() (
    tmp=$(mktemp -d) || exit 1
    trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$tmp"' EXIT
    trap 'exit 130' INT TERM

    # ---------- colors (off when piped or NO_COLOR is set) ----------
    if [ -t 1 ] && [ -z "$NO_COLOR" ]; then
        RST=$(printf '\033[0m');   BLD=$(printf '\033[1m');   DIM=$(printf '\033[2m')
        CYN=$(printf '\033[1;36m'); GRN=$(printf '\033[32m');  YEL=$(printf '\033[33m')
        RED=$(printf '\033[1;31m'); MAG=$(printf '\033[1;35m'); BLU=$(printf '\033[1;34m')
        cols=$(tput cols 2>/dev/null || echo 120)
    else
        RST=; BLD=; DIM=; CYN=; GRN=; YEL=; RED=; MAG=; BLU=
        cols=120
    fi
    TAB=$(printf '\t')
    RULE=$(printf '%*s' "$cols" '' | tr ' ' '=')

    # scan <group> <index> <dir> <depth>  (runs in background)
    scan() {
        {
            du -h --max-depth="$4" "$3" 2>/dev/null |
                sort -hr | head -n 6 | tail -n 5 > "$tmp/$1.$2.out"
            : > "$tmp/$1.$2.done"
        } &
    }

    # ready <group> <count>: true when all scans of the group are finished
    ready() {
        _i=0
        while [ "$_i" -lt "$2" ]; do
            [ -e "$tmp/$1.$_i.done" ] || return 1
            _i=$((_i + 1))
        done
    }

    # render <group> <title> <dir>...: side-by-side columns
    render() {
        _g=$1; _title=$2; shift 2
        _n=$#; _dl=; _files=; _i=0
        for _d in "$@"; do
            _dl="$_dl$_d$TAB"
            _i=$((_i + 1))
        done
        _i=0
        while [ "$_i" -lt "$_n" ]; do
            set -- "$@" "$tmp/$_g.$_i.out"
            _i=$((_i + 1))
        done
        # drop the original dir args, keep only the file args
        shift "$_n"

        awk -v n="$_n" -v cols="$cols" -v title="$_title" -v dirs="$_dl" \
            -v RST="$RST" -v DIM="$DIM" -v CYN="$CYN" -v GRN="$GRN" -v YEL="$YEL" \
            -v RED="$RED" -v MAG="$MAG" -v BLU="$BLU" -v rule="$RULE" '
        BEGIN {
            split(dirs, D, "\t")
            w = int((cols - (n - 1) * 5) / n); maxp = w - 7
            sep = "  " DIM "│" RST "  "
            for (i = 0; i < n; i++) {
                f = ARGV[i + 1]; r = 0
                while ((getline l < f) > 0 && r < 5) { row[i, r] = l; r++ }
                close(f)
            }
            dash = ""; for (k = 0; k < w; k++) dash = dash "-"

            print ""
            print CYN rule RST
            print CYN " Storage Analysis: " title RST
            print CYN rule RST

            line = ""
            for (i = 0; i < n; i++) {
                p = D[i + 1]
                if (length(p) > w) p = ".." substr(p, length(p) - w + 3)
                line = line BLU sprintf("%-" w "s", p) RST
                if (i < n - 1) line = line sep
            }
            print line

            line = ""
            for (i = 0; i < n; i++) {
                line = line DIM dash RST
                if (i < n - 1) line = line sep
            }
            print line

            for (r = 0; r < 5; r++) {
                line = ""
                for (i = 0; i < n; i++) {
                    l = row[i, r]; size = ""; p = ""
                    if (l != "") {
                        t = index(l, "\t"); size = substr(l, 1, t - 1); p = substr(l, t + 1)
                        base = D[i + 1]
                        if (p == base) p = "."
                        else if (index(p, base "/") == 1) p = substr(p, length(base) + 2)
                        if (length(p) > maxp) p = ".." substr(p, length(p) - maxp + 3)
                    }
                    u = substr(size, length(size), 1)
                    c = (u == "K") ? GRN : (u == "M") ? YEL : (u == "G") ? RED : \
                        (u == "T" || u == "P") ? MAG : DIM
                    line = line c sprintf("%6s", size) RST " " sprintf("%-" maxp "s", p)
                    if (i < n - 1) line = line sep
                }
                print line
            }
            exit
        }' "$@"
    }

    # ---------- directories ----------
    H1=/home/shared;  H2=/home/kira
    G1=/home/kira/git/devopsnextgenx
    G2=/home/kira/git/amitkshirsagar13
    G3=/home/kira/tmp

    # ---------- start every scan at once ----------
    scan host 0 "$H1" 3; scan host 1 "$H2" 3
    scan git  0 "$G1" 1; scan git  1 "$G2" 1; scan git 2 "$G3" 1

    # ---------- filesystem (instant, shown while scans run) ----------
    echo "${CYN}${RULE}${RST}"
    echo "${CYN} FILESYSTEM${RST}"
    echo "${CYN}${RULE}${RST}"
    df -h /home

    # ---------- print each group as soon as all of its scans finish ----------
    hp=0; gp=0
    while [ "$hp" -eq 0 ] || [ "$gp" -eq 0 ]; do
        if [ "$hp" -eq 0 ] && ready host 2; then
            render host "Host" "$H1" "$H2"; hp=1
        fi
        if [ "$gp" -eq 0 ] && ready git 3; then
            render git "git" "$G1" "$G2" "$G3"; gp=1
        fi
        [ "$hp" -eq 1 ] && [ "$gp" -eq 1 ] || sleep 0.1
    done

    echo
    echo "${CYN}${RULE}${RST}"
    echo "${BLD} du5x <path>${RST}"
    echo "${CYN}${RULE}${RST}"
)

# aliases (add to ~/.bashrc or ~/.zshrc)
alias fpm='~/bin/flatpak-manage.sh'          # full run: update + audit
alias fpm-check='~/bin/flatpak-manage.sh --check'   # audit only, no changes
alias fpm-report='cat "$(ls -t ~/.local/state/flatpak-manage/report-* | head -1)"'

du5x() {
    du -h --max-depth=1 "${1:-.}" | sort -hr | head -n 6 | tail -n 5
}
