typeset -gx \
  LANG=en_US.UTF-8 \
  # NOTE: LANG is exported but NOT readonly because vcs_info temporarily sets to C (?)

typeset -grx \
  FLAKE_DIR="$HOME/.dotfiles/nix/darwin" \
  SYSTEM_FLAKE="$HOME/.dotfiles/nix/darwin/flake.nix" \
  TRASHDIR="$HOME/.local/share/Trash" \
  RECENT_NVIM="$HOME/.local/bin/nvim" \
  REAL_NVIM="${NIX_CURRENT_USER:-$HOME/.nix-profile}/bin/nvim" \
  LC_ALL=en_US.UTF-8 \
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  NIX_CURRENT_SYSTEM=/run/current-system/sw \
  NIX_CURRENT_USER="${NIX_CURRENT_USER:-$HOME/.nix-profile}" \
  EDITOR="$RECENT_NVIM" \
  VISUAL="$RECENT_NVIM" \
  DIRVIEWER=yazi
