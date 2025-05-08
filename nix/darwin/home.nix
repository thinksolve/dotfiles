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
    # Add other dotfiles as needed
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

  programs.home-manager.enable = true;

}
