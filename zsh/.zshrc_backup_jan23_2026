export ZSH_CONFIG=~/.dotfiles/zsh/

# source ~/.config/path.sh 

source $ZSH_CONFIG/constants.zsh
source $ZSH_CONFIG/.shell_functions.sh
source $ZSH_CONFIG/bindkeys.zsh
source $ZSH_CONFIG/aliases.zsh
source $ZSH_CONFIG/preferences.zsh
source $ZSH_CONFIG/terminal_styling.zsh 


source $ZSH_CONFIG/fast_compinit.zsh
source $ZSH_CONFIG/after_compinit.zsh #carapace, fbat 



_plugins_zsh=$HOME/.zsh_plugins.zsh
_plugins_txt=$HOME/.zsh_plugins.txt

if [[ -f $_plugins_txt && ( ! -f $_plugins_zsh || $_plugins_txt -nt $_plugins_zsh ) ]]; then
    # txt is newer (or static file missing) → regenerate
    echo 'sourcing plugins txt file'
    source "$NIX_CURRENT_USER/share/antidote/antidote.zsh"
    antidote load
elif [[ -f $_plugins_zsh ]]; then
    source $_plugins_zsh
fi

# eval "$(direnv hook zsh)" ... 'dev' function better now

# export FZD_MAXDEPTH=5
do_exit_cleanup() {
    fzd.cleanup
    # echo "Shell exit: Cleanups complete" >&2
}

trap do_exit_cleanup EXIT



