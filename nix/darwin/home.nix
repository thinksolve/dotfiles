{
  config,
  pkgs,
  username,
  ...
}:
let
  dotfiles_dir = "${config.home.homeDirectory}/.dotfiles";
  link_dotfiles = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles_dir}/${path}";
in
{
  # home.username = username;
  home.homeDirectory = "/Users/${username}";
  # home.homeDirectory = "/Users/${config.home.username}";
  # home.homeDirectory = lib.mkForce "/Users/brightowl";
  # home.stateVersion = "24.11";
  home.stateVersion = "23.11";

  home.file = {
    ".hammerspoon".source = link_dotfiles "/hammerspoon";
    ".zshrc".source = link_dotfiles "/zsh/.zshrc";
    ".tmux.conf".source = link_dotfiles "/tmux/.tmux.conf";
    ".shell_functions.sh".source = link_dotfiles "/zsh/.shell_functions.sh";
    ".config/nvim".source = link_dotfiles "/nvim";
    ".config/iterm2".source = link_dotfiles "/iterm2";
    ".config/yazi".source = link_dotfiles "/yazi";
    ".config/nix".source = link_dotfiles "/nix";
    ".config/nix-darwin".source = link_dotfiles "/nix/darwin";
    # Doom Emacs configs (symlinked to ~/.doom.d)
    # - Depends on emacs-mac (flake.nix's homebrew.brews)
    ".doom.d/init.el".source = link_dotfiles "/doom/init.el";
    ".doom.d/config.el".source = link_dotfiles "/doom/config.el";
    ".doom.d/packages.el".source = link_dotfiles "/doom/packages.el";
  };

  # home.sessionVariables =
  #   {
  #   };
  #
  # home.sessionPath = [
  #   "/run/current-system/sw/bin"
  #   "$HOME/.nix-profile/bin"
  # ];

  #NOTE: testing
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    # enableSyntaxHighlighting = true;
    # enableAutosuggestions = true;
    # ohMyZsh = {
    #   enable = true;
    #   # plugins = [
    #   #   "git"
    #   #   "vi-mode"
    #   #   "zsh-autosuggestions"
    #   #   "zsh-syntax-highlighting"
    #   # ];
    #   theme = "robbyrussell";
    # };
    enableCompletion = true;
    completionInit = ''
      # Filter fpath to avoid broken/missing dirs
      fpath=(${"fpath:A"}(:aN))

      # Run compinit safely
      autoload -Uz compinit && compinit -i 
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    '';

    initExtra = ''
      mkdir -p $HOME/tmp
      echo "Home Manager managing Zsh" > $HOME/tmp/zsh-managed.log
      export DISABLE_AUTO_UPDATE=true


      # From your .zshrc
      setopt HIST_IGNORE_ALL_DUPS
      export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH


      # Configure pure prompt
      fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
      autoload -U promptinit; promptinit
      prompt pure
    '';

  };

  home.activation.emacsSetup = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # Ensure SSH is available
    export PATH=${pkgs.openssh}/bin:/opt/homebrew/bin:$PATH
    # Backup non-Doom or invalid .emacs.d
    if [ -e "$HOME/.emacs.d" ] && { [ ! -d "$HOME/.emacs.d/.git" ] || ! ${pkgs.git}/bin/git -C "$HOME/.emacs.d" rev-parse HEAD >/dev/null 2>&1; }; then
      ${pkgs.coreutils}/bin/mv -f "$HOME/.emacs.d" "$HOME/.emacs.d.bak-$(date +%Y%m%d%H%M%S)"
      echo "Backed up non-Doom or invalid .emacs.d to ~/.emacs.d.bak-$(date +%Y%m%d%H%M%S)"
    fi
    # Clone Doom Emacs if not present or invalid
    if [ ! -d "$HOME/.emacs.d" ] || [ ! -d "$HOME/.emacs.d/.git" ] || ! ${pkgs.git}/bin/git -C "$HOME/.emacs.d" rev-parse HEAD >/dev/null 2>&1; then
      ${pkgs.git}/bin/git clone --depth 1 git@github-thinksolve:doomemacs/doomemacs.git "$HOME/.emacs.d"
      $HOME/.emacs.d/bin/doom install --no-config --no-fonts
      echo "Installed Doom Emacs"
    fi
    # Sync Doom to apply configs
    $HOME/.emacs.d/bin/doom sync
    echo "Synced Doom Emacs configs"
    # Alias Emacs.app to /Applications for GUI access
    if [ -d "/opt/homebrew/opt/emacs-mac@29/Emacs.app" ] && [ ! -e "/Applications/Emacs.app" ]; then
      ${pkgs.coreutils}/bin/ln -sf "/opt/homebrew/opt/emacs-mac@29/Emacs.app" "/Applications/Emacs.app"
      echo "Aliased Emacs.app to /Applications"
    fi
  '';

  programs.home-manager.enable = true;

}
