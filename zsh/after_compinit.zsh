# ~/.dotfiles/zsh/after_compinit.zsh
#
autoload -Uz add-zsh-hook

_lazy_wrapper() {
    # ensure completion system exists
    if ! typeset -f compinit >/dev/null; then
        autoload -Uz compinit && compinit -C
    fi

 
    # -----  CARAPACE  -----
    source <(carapace _carapace zsh)
    
    # NOTE: Force file completions to use standard _files instead of carapace
    # This allows fzf-tab to work again with ls, nvim, etc 
    compdef _files ls nvim cat bat vim code
    compdef _path_files cd pushd rmdir


    # -----  FBAT  -----
    fbat() {
      (($#)) && functions "$1" | bat -l zsh --color=always \
             || echo "Usage: fbat <function>"
    }

    # compdef  ''  fbat           # erase any previous completer
    compdef  _functions  fbat   # assign the right one
    # -----  FBAT  -----


    add-zsh-hook -d precmd _lazy_wrapper
}

add-zsh-hook precmd _lazy_wrapper
