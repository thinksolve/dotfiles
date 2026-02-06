# ~/.dotfiles/zsh/after_compinit.zsh
_carapace_patch_for_fzf-tab_path_completions(){
    #NOTE: without this fzf-tab breaks on _path_ completions for the listed tools below
    # I.e., i only want carapace to handle _flag_ completions
    compdef _files bat cat code cp eza head less ls more mv nvim rat rm tail touch tree vim
    compdef _path_files cd mkdir pushd rmdir
}

autoload -Uz add-zsh-hook

_lazy_wrapper() {
    # ensure completion system exists
    if ! typeset -f compinit >/dev/null; then
        autoload -Uz compinit && compinit -C
    fi

    # -----  CARAPACE  -----
    source <(carapace _carapace zsh)
    _carapace_patch_for_fzf-tab_path_completions

    # these functions are typically found in ~/.shell_functions.sh
    compdef  _functions  fbat   
    compdef _command_names wdef

    add-zsh-hook -d precmd _lazy_wrapper
}

add-zsh-hook precmd _lazy_wrapper
