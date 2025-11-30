#base
export LANG=en_US.UTF-8 
export LC_ALL=en_US.UTF-8 
export LOGANDRUN=log-and-run
export DIRVIEWER=yazi 
export DOTFILES=$HOME/.dotfiles  
export NIX_CURRENT_SYSTEM=/run/current-system/sw 
export NIX_CURRENT_USER="$HOME/.nix-profile" 
export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt 
# export RECENT_NVIM="$HOME/.local/bin/nvim" 
export RECENT_NVIM="$HOME/.local/bin/log-and-run" 
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt 
export TRASHDIR="$HOME/.local/share/Trash" 

#derived
export EDITOR="$RECENT_NVIM" 
export FLAKE_DIR="$DOTFILES/nix/darwin" 
export REAL_NVIM="$NIX_CURRENT_USER/bin/nvim"  
export SYSTEM_FLAKE="$DOTFILES/nix/darwin/flake.nix" 
export VISUAL="$RECENT_NVIM" 


