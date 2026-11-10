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
export PATH="$PATH:~/.cache/lm-studio/bin"
export OLLAMA_API_KEY="ollama"
export OLLAMA_BASE_URL="http://localhost:11434/v1"

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
[[ -f ~/git/devopsnextgenx/gnome-extensions/gui-react-ollama/node_modules/tabtab/.completions/electron-forge.zsh ]] && . ~/git/devopsnextgenx/gnome-extensions/gui-react-ollama/node_modules/tabtab/.completions/electron-forge.zsh
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

# . "$HOME/.local/bin/env"
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
export PATH="$PATH:~/.lmstudio/bin"
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# alias chat-server='~/bin/llama-turbo-server -m "/home/shared/lmstudio/.lmstudio/models/mradermacher/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated-i1-GGUF/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated.i1-Q4_K_S.gguf" --port 8080 --host 0.0.0.0'
alias chat-server='~/bin/llama-turbo-server -m "/home/shared/lmstudio/.lmstudio/models/mradermacher/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated-i1-GGUF/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated.i1-Q4_K_S.gguf" --port 8080 --host 0.0.0.0 -ngl 12 --flash-attn on -c 16384 --cache-type-k turbo3 --cache-type-v turbo3 --ubatch-size 128 -n 8192'
alias novel-server='~/bin/llama-turbo-server -m "/home/shared/lmstudio/.lmstudio/models/mradermacher/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated-i1-GGUF/MN-CaptainErisNebula-12B-Chimera-v1.1-heretic-uncensored-abliterated.i1-Q4_K_S.gguf" --port 8080 --host 0.0.0.0 -ngl 12 --flash-attn on -c 32768 --cache-type-k turbo3 --cache-type-v turbo3 -n 12000 --ignore-eos --repeat-penalty 1.17 --metrics'
alias lexi-server='~/bin/llama-turbo-server -m "/home/shared/lmstudio/.lmstudio/models/bartowski/Llama-3.1-8B-Lexi-Uncensored-V2-GGUF/Llama-3.1-8B-Lexi-Uncensored-V2-Q2_K_L.gguf" --port 8080 --host 0.0.0.0 -ngl 12 --flash-attn on -c 32768 --cache-type-k turbo3 --cache-type-v turbo3 -n 12000 --ignore-eos --repeat-penalty 1.17 --metrics'
alias zbox='ssh admn@192.168.12.111'

# opencode
export PATH=~/.opencode/bin:$PATH
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
export PATH="~/.nvm/versions/node/v24.0.1/bin:$PATH"
export PATH="~/.nvm/versions/node/v24.0.1/bin:$PATH"

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
# du5 - colorful, side-by-side, concurrent storage report (bash AND zsh)
# Add to ~/.bashrc or ~/.zshrc (or: source du5.sh)
# Force colors when piping: DU5_COLOR=1 du5 | less -R   |   disable: NO_COLOR=1

du5() (
    tmp=$(mktemp -d) || exit 1
    trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$tmp"' EXIT
    trap 'exit 130' INT TERM

    if { [ -t 1 ] || [ -n "$DU5_COLOR" ]; } && [ -z "$NO_COLOR" ]; then
        COLOR=1; cols=$(tput cols 2>/dev/null || echo 120)
    else
        COLOR=0; cols=120
    fi
    TAB=$(printf '\t')
    RULE=$(printf '%*s' "$cols" '' | tr ' ' '=')

    # banner <bg-256color> <fg-256color> <text>
    banner() {
        if [ "$COLOR" -eq 1 ]; then
            printf '\033[48;5;%sm\033[1;38;5;%sm%-*s\033[0m\n' "$1" "$2" "$cols" " $3"
        else
            printf '%s\n %s\n%s\n' "$RULE" "$3" "$RULE"
        fi
    }

    # scan <group> <index> <dir> <depth>  (background)
    scan() {
        {
            du -h --max-depth="$4" "$3" 2>/dev/null |
                sort -hr | head -n 6 | tail -n 5 > "$tmp/$1.$2.out"
            : > "$tmp/$1.$2.done"
        } &
    }

    ready() {
        _i=0
        while [ "$_i" -lt "$2" ]; do
            [ -e "$tmp/$1.$_i.done" ] || return 1
            _i=$((_i + 1))
        done
    }

    # render <group> <title> <banner-bg> <dir>...
    render() {
        _g=$1; _title=$2; _bg=$3; shift 3
        _n=$#; _dl=; _i=0
        for _d in "$@"; do _dl="$_dl$_d$TAB"; done
        while [ "$_i" -lt "$_n" ]; do
            set -- "$@" "$tmp/$_g.$_i.out"
            _i=$((_i + 1))
        done
        shift "$_n"

        echo
        banner "$_bg" 231 "▣ Storage Analysis: $_title"

        awk -v n="$_n" -v cols="$cols" -v dirs="$_dl" -v color="$COLOR" '
        function fg(c) { return color ? sprintf("%c[38;5;%dm", 27, c) : "" }
        function bytes(s,   v, u, m) {
            v = s + 0; u = substr(s, length(s), 1)
            m = (u=="K") ? 1024 : (u=="M") ? 1048576 : (u=="G") ? 1073741824 : (u=="T") ? 1099511627776 : 1
            return v * m
        }
        function mix(a, b, t) { return a + (b - a) * t }
        function q(r, g, b) {   # RGB -> nearest xterm-256 color cube index
            return 16 + 36 * int(r / 255 * 5 + 0.5) + 6 * int(g / 255 * 5 + 0.5) + int(b / 255 * 5 + 0.5)
        }
        # size gradient (log scale inside each band):
        #   >=1G red | 500M-1G yellow->red | 10M-500M green->yellow | <10M blue->green
        function gcolor(b,   t, lb) {
            if (b >= 1073741824) return q(255, 0, 0)
            if (b >= 524288000) {
                t = (log(b) - log(524288000)) / (log(1073741824) - log(524288000))
                return q(255, mix(255, 0, t), 0)
            }
            if (b >= 10485760) {
                t = (log(b) - log(10485760)) / (log(524288000) - log(10485760))
                return q(mix(0, 255, t), 255, 0)
            }
            lb = (b < 1024) ? 1024 : b
            t = (log(lb) - log(1024)) / (log(10485760) - log(1024))
            return q(mix(40, 0, t), mix(130, 255, t), mix(255, 0, t))
        }
        function szcolor(s) { return gcolor(bytes(s)) }
        BEGIN {
            R = color ? sprintf("%c[0m", 27) : ""
            B = color ? sprintf("%c[1m", 27) : ""
            split(dirs, D, "\t")
            split("81 213 220 118 141", ACC, " ")
            w = int((cols - (n - 1) * 5) / n); bw = 8; maxp = w - 7 - bw - 1
            sep = "  " fg(240) "│" R "  "

            for (i = 0; i < n; i++) {
                f = ARGV[i + 1]; r = 0; mx[i] = 1
                while ((getline l < f) > 0 && r < 5) {
                    row[i, r] = l; r++
                    b = bytes(substr(l, 1, index(l, "\t") - 1)); if (b > mx[i]) mx[i] = b
                }
                close(f)
            }

            # column headers
            line = ""
            for (i = 0; i < n; i++) {
                p = D[i + 1]
                if (length(p) > w - 2) p = ".." substr(p, length(p) - w + 5)
                line = line fg(ACC[i + 1]) B "▌" sprintf("%-" (w - 1) "s", p) R
                if (i < n - 1) line = line sep
            }
            print line
            line = ""
            for (i = 0; i < n; i++) {
                d = ""; for (k = 0; k < w; k++) d = d "━"
                line = line fg(ACC[i + 1]) d R
                if (i < n - 1) line = line sep
            }
            print line

            # rows
            for (r = 0; r < 5; r++) {
                line = ""
                for (i = 0; i < n; i++) {
                    l = row[i, r]; size = ""; p = ""; bar = ""; c = szcolor("")
                    if (l != "") {
                        t = index(l, "\t"); size = substr(l, 1, t - 1); p = substr(l, t + 1)
                        base = D[i + 1]
                        if (p == base) p = "."
                        else if (index(p, base "/") == 1) p = substr(p, length(base) + 2)
                        if (length(p) > maxp) p = ".." substr(p, length(p) - maxp + 3)
                        c = szcolor(size)
                        fill = int(bw * bytes(size) / mx[i] + 0.5); if (fill < 1) fill = 1
                        for (k = 0; k < bw; k++)
                            bar = bar ((k < fill) ? fg(c) "█" : fg(238) "░")
                    } else {
                        for (k = 0; k < bw; k++) bar = bar " "
                    }
                    # path: dim parent, bright leaf
                    pad = maxp - length(p); if (pad < 0) pad = 0
                    lp = 0; for (k = length(p); k >= 1; k--) if (substr(p, k, 1) == "/") { lp = k; break }
                    pp = fg(244) substr(p, 1, lp) fg(255) B substr(p, lp + 1) R
                    line = line fg(c) B sprintf("%6s", size) R " " bar R " " pp sprintf("%" pad "s", "")
                    if (i < n - 1) line = line sep
                }
                print line
            }
            exit
        }' "$@"
    }

    H1=/home/shared;  H2=~
    G1=~/git/devopsnextgenx
    G2=~/git/amitkshirsagar13
    G3=~/tmp

    scan host 0 "$H1" 3; scan host 1 "$H2" 3
    scan git  0 "$G1" 1; scan git  1 "$G2" 1; scan git 2 "$G3" 1

    # filesystem (instant) with colored Use%
    banner 36 16 "▣ FILESYSTEM"
    df -h /home | awk -v color="$COLOR" '
        function fg(c) { return color ? sprintf("%c[38;5;%dm", 27, c) : "" }
        BEGIN { R = color ? sprintf("%c[0m", 27) : ""; B = color ? sprintf("%c[1m", 27) : "" }
        NR == 1 { printf "%s%-16s %6s %6s %6s  %4s  %-20s  %s%s\n", fg(244) B, $1, $2, $3, $4, $5, "Usage", "Mounted on", R; next }
        { p = $5 + 0; c = (p >= 90) ? 196 : (p >= 70) ? 220 : 46
          d = 20; bar = ""; f = int(d * p / 100 + 0.5)
          for (k = 0; k < d; k++) bar = bar ((k < f) ? fg(c) "█" : fg(238) "░")
          printf "%s%-16s%s %6s %6s %6s  %s%4s%s  %s%s  %s%s%s\n", fg(81), $1, R, $2, $3, $4, fg(c) B, $5, R, bar, R, fg(213), $6, R }'

    hp=0; gp=0
    while [ "$hp" -eq 0 ] || [ "$gp" -eq 0 ]; do
        if [ "$hp" -eq 0 ] && ready host 2; then
            render host "Host" 27 "$H1" "$H2"; hp=1
        fi
        if [ "$gp" -eq 0 ] && ready git 3; then
            render git "git" 91 "$G1" "$G2" "$G3"; gp=1
        fi
        [ "$hp" -eq 1 ] && [ "$gp" -eq 1 ] || sleep 0.1
    done

    echo
    banner 238 220 "▣ du5x <path>   — drill into any directory"
)

# aliases (add to ~/.bashrc or ~/.zshrc)
alias fpm='~/bin/flatpak-manage.sh'          # full run: update + audit
alias fpm-check='~/bin/flatpak-manage.sh --check'   # audit only, no changes
alias fpm-report='cat "$(ls -t ~/.local/state/flatpak-manage/report-* | head -1)"'

du5x() {
    du -h --max-depth=1 "${1:-.}" | sort -hr | head -n 6 | tail -n 5
}
