# ~/.dotfiles/zsh/fast_compinit.zsh

# --- completion system -------------------------------------------------------
autoload -Uz compinit
ZC="${ZDOTDIR:-$HOME}/.zcompdump"

# # Use cache if fresh; NOTE: when nuking zcompdump this logic doesnt return autocompletion in all cases
# compinit -C -d "$ZC"

# Only use cache if it exists, otherwise rebuild
if [[ -f "$ZC" ]]; then
    compinit -C -d "$ZC"
else
    compinit -d "$ZC"   # rebuild if dump missing
fi

# Compile cache (silent)
if [[ -f "$ZC" && (! -f "$ZC.zwc" || "$ZC" -nt "$ZC.zwc") ]]; then
    zcompile "$ZC" 2>/dev/null
fi


## NOTE: is this still useful?
# # Don't ask before showing many completions
# zstyle ':completion:*' verbose yes
# zstyle ':completion:*' list-prompt ''
# zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
# zstyle ':completion:*' menu yes select
# zstyle ':completion:*' use-cache yes             # speed
# zstyle ':completion:*' cache-path "$HOME/.zcompcache"


## OLD:
# autoload -U compinit
# compinit -C -d "${ZDOTDIR:-$HOME}/.zcompdump"
# zcompile "${ZDOTDIR:-$HOME}/.zcompdump" 2>/dev/null


