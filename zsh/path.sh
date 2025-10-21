# ~/.dotfiles/shell/path.sh  – works in sh, bash, zsh

# prepend_path() {
#   case ":$PATH:" in
#     *":$1:"*) ;;          # already present
#     *)  PATH="$1${PATH:+:$PATH}" ;;
#   esac
# }
#
# prepend_path "/run/current-system/sw/bin"
# prepend_path "$HOME/.nix-profile/bin"
# prepend_path "$HOME/.local/bin"
# prepend_path "$HOME/.config/emacs/bin"
# prepend_path "$HOME/bin"
# prepend_path "/usr/local/bin"
# prepend_path "$PNPM_HOME"
# export PATH
#

export PNPM_HOME=/Users/brightowl/Library/pnpm
export NIX_CURRENT_SYSTEM_BIN=/run/current-system/sw/bin

export PATH="$NIX_CURRENT_SYSTEM_BIN:$HOME/.nix-profile/bin:$HOME/.local/bin:$HOME/.config/emacs/bin:$HOME/bin:/usr/local/bin:$PNPM_HOME:$PATH"
