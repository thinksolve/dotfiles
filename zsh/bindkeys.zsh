bindkey -v

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down


function bindkey_minimal() {
    local key=$1 
    local func=$2
    local widget=_${func}_widget

    # dynamic function definition (at runtime; other way uses eval "$widget(){...}")
    functions[$widget]="() { $func; }" 

    zle -N  $widget
    bindkey "$key" $widget
}


bindkey_minimal '^[k' copylast
bindkey_minimal '^[r' recent

fzd_file() { fzd 'file' }
bindkey_minimal '^[f' fzd_file #old: find_dir_then_cache 

fzd_dir() { fzd 'dir' }
bindkey_minimal '^[d' fzd_dir #old: find_dir_from_cache
bindkey_minimal '^[^D' fzd


yazi_here() { yazi . }
bindkey_minimal '^[y' yazi_here

nvim_here() { nvim . }
bindkey_minimal '^[n' nvim_here



function bindkey_picker_to_buffer() {
  local key=$1 func=$2
  local widget=_${func}_widget

  functions[$widget]="
    local choice
    choice=\$( $func < /dev/tty )
    [[ -n \$choice ]] && { BUFFER=\$choice; CURSOR=\$#BUFFER; }
    zle reset-prompt
  "

  zle -N $widget
  bindkey "$key" $widget
}

bindkey_picker_to_buffer '^[h' get_history


insert-paste-assignment() {
  BUFFER='a=$(pbpaste)'
  CURSOR=1
  zle reset-prompt
}
zle -N insert-paste-assignment

for mode in viins vicmd; do
 bindkey -M $mode '^[p' insert-paste-assignment
done


# #WIP: allows expansion of alises when hitting space (feb-3-2026)
# autoload -Uz _expand_alias  # force load
# rationalise-space() {
#   zle _expand_alias
#   zle self-insert
# }
# zle -N rationalise-space
# bindkey ' ' rationalise-space
#
# # Ctrl-Space inserts a literal space
# bindkey '^ ' self-insert
