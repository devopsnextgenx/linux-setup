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
export PATH="$PATH:$HOME/.cache/lm-studio/bin:$HOME/.lmstudio/bin"
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
# Show top storage consumers and filesystem usage
du5() {
    local left="/home/shared"
    local right="/home/kira"
    local limit=7

    echo
    echo "================== FILESYSTEM =================="
    df -h /home

    echo
    echo "================== MAIN STORAGE =================="

    printf "%-75s | %-75s\n" "$left" "$right"
    printf '%s\n' "$(printf '%0.s-' {1..75})-+-$(printf '%0.s-' {1..75})"

    paste \
        <(du -h --max-depth=3 "$left" 2>/dev/null |
            sort -hr | head -n "$limit" |
            awk '{printf "%-10s %-64s\n", $1, $2}') \
        <(du -h --max-depth=3 "$right" 2>/dev/null |
            sort -hr | head -n "$limit" |
            awk '{printf "%-10s %-64s\n", $1, $2}') |
        awk -F '\t' '{printf "%-75s | %-75s\n", $1, $2}'

    # Development and temporary directories (3 columns)
    local dir1="/home/kira/git/devopsnextgenx"
    local dir2="/home/kira/git/amitkshirsagar13"
    local dir3="/home/kira/tmp"
    local width=48

    echo
    echo "================ DEVELOPMENT & TEMP STORAGE ================"

    printf "%-${width}s | %-${width}s | %-${width}s\n" \
        "$dir1" "$dir2" "$dir3"

    printf '%s\n' "$(printf '%*s' "$width" '' | tr ' ' '-')-+-$(printf '%*s' "$width" '' | tr ' ' '-')-+-$(printf '%*s' "$width" '' | tr ' ' '-')"

    paste \
        <(du -h --max-depth=1 "$dir1" 2>/dev/null | sort -hr | head -n 3) \
        <(du -h --max-depth=1 "$dir2" 2>/dev/null | sort -hr | head -n 3) \
        <(du -h --max-depth=1 "$dir3" 2>/dev/null | sort -hr | head -n 3) |
    awk -F '\t' -v w="$width" '{
        printf "%-*s | %-*s | %-*s\n", w, $1, w, $2, w, $3
    }'
}
