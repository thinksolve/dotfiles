typeset -gx LANG=en_US.UTF-8 #  NOTE: LANG is exported but NOT readonly because vcs_info temporarily sets to C (?)

#base exports
typeset -grx  DIRVIEWER=yazi \
              DOTFILES=$HOME/.dotfiles  \
              LC_ALL=en_US.UTF-8 \
              NIX_CURRENT_SYSTEM=/run/current-system/sw \
              NIX_CURRENT_USER="$HOME/.nix-profile" \
              NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
              RECENT_NVIM="$HOME/.local/bin/nvim" \
              SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
              TRASHDIR="$HOME/.local/share/Trash" 

#derived exports
typeset -grx  EDITOR="$RECENT_NVIM" \
              FLAKE_DIR="$DOTFILES/nix/darwin"  \
              REAL_NVIM="$NIX_CURRENT_USER/bin/nvim" \
              SYSTEM_FLAKE="$DOTFILES/nix/darwin/flake.nix" \
              VISUAL="$RECENT_NVIM" 
