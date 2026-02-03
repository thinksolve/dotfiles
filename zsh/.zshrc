export ZSH_CONFIG="$HOME/.dotfiles/zsh"

source $ZSH_CONFIG/constants.zsh
source $ZSH_CONFIG/.shell_functions.sh
source $ZSH_CONFIG/aliases.zsh
source $ZSH_CONFIG/bindkeys.zsh
source $ZSH_CONFIG/preferences.zsh
source $ZSH_CONFIG/terminal_styling.zsh
source $ZSH_CONFIG/fast_compinit.zsh
source $ZSH_CONFIG/after_compinit.zsh


_plugins_zsh=$HOME/.zsh_plugins.zsh
_plugins_txt=$HOME/.zsh_plugins.txt

if [[ -f $_plugins_txt && ( ! -f $_plugins_zsh || $_plugins_txt -nt $_plugins_zsh ) ]]; then
    echo 'sourcing plugins txt file'
    source "$PKGS_ANTIDOTE/share/antidote/antidote.zsh" #variable set in zshenv during nix build step
    antidote load
elif [[ -f $_plugins_zsh ]]; then
    source $_plugins_zsh
fi




do_exit_cleanup() {
    fzd.cleanup
}

trap do_exit_cleanup EXIT

