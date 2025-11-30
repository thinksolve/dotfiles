export ZSH_CONFIG=~/.dotfiles/zsh/

# source ~/.config/path.sh 
source $ZSH_CONFIG/constants.zsh
source $ZSH_CONFIG/.shell_functions.sh
source $ZSH_CONFIG/bindkeys.zsh
source $ZSH_CONFIG/preferences.zsh
source $ZSH_CONFIG/terminal_styling.zsh  # has to go after compinit (when using timestamp?)
source $ZSH_CONFIG/aliases.zsh
source $ZSH_CONFIG/lazy_wrappers.zsh
# source $ZSH_CONFIG/fast_compinit.zsh

# source "$NIX_CURRENT_USER/share/antidote/antidote.zsh"
# antidote load 
source ~/.zsh_plugins.zsh


export FZD_MAXDEPTH=5


do_exit_cleanup() {
    fzd.cleanup
    echo "Shell exit: Cleanups complete" >&2
}

trap do_exit_cleanup EXIT


# NOTE: no longer needed
# export PURE_PROMPT_PATH="$NIX_CURRENT_USER/share/zsh/site-functions/"
# fpath+=($PURE_PROMPT_PATH)
# autoload -U promptinit; promptinit
# prompt pure



#NOTE: this moved here since breaks format-on-save in ~/.shell_functions.sh, 
# and all other bash-friendly versions still print junk to fzf/terminal
# fzd_old() {
#     local mode=${1:-full}
#     local root=${2:-$HOME}
#     local root_hash
#     root_hash=$(md5sum <<<"$root" | cut -d' ' -f1)
#     local session_id="session_$$"
#
#
#     # session/persistent caches
#     local cache
#     case $mode in
#         file) cache="/tmp/deep-fzf-file-${root_hash}-${session_id}" ;;
#         full) cache="/tmp/deep-fzf-full-${root_hash}-${session_id}" ;;
#         dir)  cache="/tmp/deep-fzf-dir-${root_hash}" ;;
#         *)    echo "Usage: fzd-new {file|full|dir}" >&2; return 1 ;;
#     esac
#
#
#
#     # fd type flags
#     local type_flags=()
#     case $mode in
#         file) type_flags=(-t f) ;;
#         dir)  type_flags=(-t d) ;;
#         full) type_flags=() ;;
#     esac
#
#     local editor=${EDITOR:-nvim}
#     local dir_viewer=${DIRVIEWER:-$editor}
#     local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else command -v bat >/dev/null && bat --color=always {} || cat {} 2>/dev/null; fi"
#     # local dir_exclusions=(node_modules .git .cache .DS_Store venv __pycache__ Trash "*.bak" "*.log")
#     local fd_args=(-H -L . "$root" --exclude 'node_modules' --exclude '.git' --max-depth ${FZD_MAXDEPTH:-3})
#     local fzf_args=(--preview "$preview" --bind "ctrl-d:become(zsh -ic 'fzd full {}')")
#
#     # makes using while loop below tolerable, otherwise have to interpolate `||break` everywhere
#     menu_cycle() {
#         local chosen
#
#         if [[ -f $cache && -s $cache ]]; then
#             # Re-check before cat (race-proof)
#             if [[ -f $cache && -s $cache ]]; then
#                 cat "$cache" | fzf "${fzf_args[@]}" | IFS= read -r chosen
#             else
#                 # Fallback live if vanished
#                 fd "${type_flags[@]}" "${fd_args[@]}" | fzf "${fzf_args[@]}" | IFS= read -r chosen
#             fi
#         else
#             # Bg cache: Silent, no job prints
#             (fd "${type_flags[@]}" "${fd_args[@]}" > "$cache") &>/dev/null &!
#             fd "${type_flags[@]}" "${fd_args[@]}"  | fzf "${fzf_args[@]}" | IFS= read -r chosen
#         fi
#         [[ $? -ne 0 || -z $chosen ]] && return 1
#         if [[ -d $chosen ]]; then
#             "$dir_viewer" "$chosen"
#         elif editable_path "$chosen"; then
#             "$editor" "$chosen"
#         else
#             open "$chosen"
#         fi
#         [[ $? -ne 0 ]] && return 1
#         return 0
#     }
#
#     while menu_cycle; do :; done
# }
