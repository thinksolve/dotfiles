autoload -Uz add-zsh-hook

_carapace_lazy_wrapper() {
    unfunction _carapace_lazy_wrapper
    typeset -f compinit >/dev/null || autoload -Uz compinit && compinit -C
    source <(carapace _carapace zsh)
}

add-zsh-hook precmd _carapace_lazy_wrapper

