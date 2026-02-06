# ~/.dotfiles/zsh/terminal_styling.zsh

# ------ styling essentially replaces pure prompt --------------
autoload -Uz add-zsh-hook vcs_info
zstyle ':vcs_info:git:*' formats ' %F{#8a8a8a}(%b%u)%f'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'

setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f${vcs_info_msg_0_} 
%F{magenta}❯%f '
# RPROMPT='%F{241}%D{%H:%M:%S}%f${CMD_TIME:+ %F{yellow}$CMD_TIME%f'
add-zsh-hook precmd vcs_info


## NOTE: actually not needed ... 
# # ensure the `:completion` system is loaded (sanity guard check)
# if ! typeset -f compinit > /dev/null; then
#     autoload -Uz compinit && compinit -C
# fi

# # ------ feb-4-2026 currently not needed since fzf-tab overrides --------------
# zstyle ':completion:*' verbose yes
# zstyle ':completion:*' list-prompt ''
# zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
# zstyle ':completion:*' menu yes select
# zstyle ':completion:*' use-cache yes             # speed
# zstyle ':completion:*' cache-path "$HOME/.zcompcache"

