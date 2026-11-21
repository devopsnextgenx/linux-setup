# zsh shim: alias.env is bash-only, so run `llm` inside a bash subshell
export LLM_ROOT="${LLM_ROOT:-/home/shared}"
export LLM_BIN_ROOT="$LLM_ROOT/bin"
typeset -U path
path=("$LLM_BIN_ROOT" $path)

llm() { bash -c 'source "$1"; shift; llm "$@"' _ "$LLM_BIN_ROOT/alias.env" "$@"; }

# tab completion (only registered if compinit has already run)
if (( $+functions[compdef] )); then
  _llm() {
    local -a k
    k=(${(f)"$(awk '/^llm_add /{print $2}' "$LLM_BIN_ROOT/alias.env")"}
       bench stop logs list -d --detach --help --recompile --remote --local --backend --port --ctx --api-key)
    compadd -a k
  }
  compdef _llm llm
fi
