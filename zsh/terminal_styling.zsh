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
# ------ styling essentially replaces pure prompt --------------
