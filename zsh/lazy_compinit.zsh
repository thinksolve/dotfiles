# ~/.dotfiles/zsh/lazy_compinit.zsh

autoload -Uz add-zsh-hook

_maybe_compinit() {
  # first time any completion is attempted: load the system
  autoload -Uz compinit && compinit -C
  # register your custom completer *now*, while tables are virgin
  compdef _functions fbat
  # remove the hook so we never run again
  add-zsh-hook -d precmd _maybe_compinit
  # re-try the current completion
  # zle complete-word
}

zle -N _maybe_compinit _maybe_compinit
bindkey '^I' _maybe_compinit   # <Tab> triggers it
