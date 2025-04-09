# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/powerlevel10k/powerlevel10k.zsh-theme
source /home/shared/pyenv/bin/activate
source ~/.nvm/nvm.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
SAVEHIST=1000  # Save most-recent 1000 lines
HISTFILE=~/.zsh_history

if [[ -d "$HOME/bin" ]]; then
    PATH="$HOME/bin:/home/shared/apps/JetBrains/Toolbox/scripts:$PATH"
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/kira/.cache/lm-studio/bin"

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
