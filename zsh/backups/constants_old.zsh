## (A) ARRAY SOLUTION
export_array() {
  local var
  for var in "$@"; do
    export "$var"
  done
}

base_vars=(
  LANG=en_US.UTF-8
  LC_ALL=en_US.UTF-8
  DOTFILES=$HOME/.dotfiles
  RECENT_NVIM=$HOME/.local/bin/nvim
  NIX_CURRENT_USER=$HOME/.nix-profile
)
export_array "${base_vars[@]}"

derived_vars=(
  EDITOR=$RECENT_NVIM
  FLAKE_DIR=$DOTFILES/nix/darwin
  REAL_NVIM=$NIX_CURRENT_USER/bin/nvim
  VISUAL=$RECENT_NVIM
)
export_array "${derived_vars[@]}"



# ## (B) WHILE-HEREDOC SOLUTION
# export_block() {
#   while IFS= read -r line; do
#     line=${line##[[:space:]]}   # remove leading spaces/tabs
#     [[ -z $line ]] && continue
#     export "$line"
#   done
# }
#
# export_block <<BLOCK
#   DIRVIEWER=yazi
#   DOTFILES=$HOME/.dotfiles
#   NIX_CURRENT_SYSTEM=/run/current-system/sw
#   NIX_CURRENT_USER=$HOME/.nix-profile
#   NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
#   RECENT_NVIM=$HOME/.local/bin/nvim
#   SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# BLOCK
#
# export_block <<BLOCK
#   TRASHDIR=$HOME/.local/share/Trash
#   EDITOR=$RECENT_NVIM
#   FLAKE_DIR=$DOTFILES/nix/darwin/
#   REAL_NVIM=$NIX_CURRENT_USER/bin/nvim
#   SYSTEM_FLAKE=$DOTFILES/nix/darwin/flake.nix
#   VISUAL=$RECENT_NVIM
# BLOCK
