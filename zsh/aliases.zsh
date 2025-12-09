alias dotfiles="cd ~/.dotfiles/"
alias rop="recent"
alias wvim="$RECENT_NVIM"

alias rm='trash-put' 
#deletes to ~/.local/share/Trash/; other commands trash-restore, trash-empty; accepts -r -f flags 

# alias rm='rm -I --preserve-root' #safeguard, but permanent deletion
alias lz="eza"
alias drs='sudo darwin-rebuild switch --flake ~/.dotfiles/nix/darwin'
alias config='cd ~/.dotfiles/ && yazi .'
alias config-nix='cd ~/.dotfiles/nix/darwin && yazi .'
# alias evim='emacs -nw' # not really useful now that im using emacsclient
alias zshrc='nvim ~/.zshrc'
alias hist='nvim ~/.zsh_history'
alias shell_functions='nvim ~/.shell_functions.sh'
alias SCREENSAVERS='cd "/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS"'
# alias BRAVE='cd ${HOME}/Library/Application\ Support/BraveSoftware/Brave-Browser/afalakplffnnnlkncjhbmahjfjhmlkal/1.0.904/1/'

# alias snake="tr '[ ]-' '_'"
# alias kebab="tr '[ ]_' '-'"
# alias upper="tr 'a-z' 'A-Z'"
# alias lower="tr 'A-Z' 'a-z'"

# Avoids polluting session & zsh history as with `bindkey -s ...`


# python (standard) redefinitions
alias pip=pip3
alias python2=python
alias python=python3
