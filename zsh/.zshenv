# ═══════════════════════ NIX-MANAGED-BLOCK-START ═══════════════════════
export PKGS_ANTIDOTE=/nix/store/wnhffjdkbk4xwbf32flnzl03rdjbx00h-antidote-1.9.10
export PKGS_NVIM=/nix/store/rpm9l8ji9a9pb2q5kjwi7r2dbbm3hl1p-neovim-0.11.5
# ═══════════════════════ NIX-MANAGED-BLOCK-END ═══════════════════════



# Locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# SSL certs
export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Nix locations (used in PATH and for reference)
export NIX_CURRENT_SYSTEM=/run/current-system/sw
export NIX_CURRENT_USER=$HOME/.nix-profile
export HM_PROFILE="$HOME/.local/state/nix/profiles/home-manager"
export HOMEBREW_BIN="/opt/homebrew/bin"
export PNPM_HOME=$HOME/Library/pnpm


# Nix package paths
#not useful anymore?: export REAL_NVIM="/nix/store/rpm9l8ji9a9pb2q5kjwi7r2dbbm3hl1p-neovim-0.11.5/bin/nvim"

# PATH
export PATH="$HM_PROFILE/bin:$NIX_CURRENT_SYSTEM/bin:$NIX_CURRENT_USER/bin:$HOME/.local/bin:$HOME/.config/emacs/bin:$HOME/bin:/usr/local/bin:$PNPM_HOME:$HOMEBREW_BIN:$PATH"

