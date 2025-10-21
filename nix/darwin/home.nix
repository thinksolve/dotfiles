{
  config,
  pkgs,
  username,
  lib,
  ...
}:
let
  dotfiles_dir = "${config.home.homeDirectory}/.dotfiles";
  link_dotfiles = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles_dir}/${path}";
in
{
  home.username = lib.mkForce username;
  home.homeDirectory = lib.mkForce "/Users/${username}";

  # home.username = username;
  # home.homeDirectory = "/Users/${username}";  <-- commented out oct 2025

  # home.homeDirectory = "/Users/${config.home.username}";
  # home.homeDirectory = lib.mkForce "/Users/brightowl";
  # home.stateVersion = "24.11";
  home.stateVersion = "23.11";

  home.file = {
    "/Library/Application Support/com.mitchellh.ghostty/config".source =
      link_dotfiles "/ghostty/config";
    ".local/bin/nvim" = {
      source = link_dotfiles "/bin/nvim-recent"; # source in dotfiles repo
      executable = true; # chmod +x done by HM
    };
    ".local/bin/yt-txt" = {
      source = link_dotfiles "/bin/yt-txt";
      executable = true;
    };
    ".hammerspoon".source = link_dotfiles "/hammerspoon";
    ".config/path.sh".source = link_dotfiles "/zsh/path.sh";
    ".zshrc".source = link_dotfiles "/zsh/.zshrc";
    ".zsh_plugins.zsh".source = link_dotfiles "/zsh/.zsh_plugins.zsh";
    ".zsh_plugins.txt".source = link_dotfiles "/zsh/.zsh_plugins.txt";
    ".tmux.conf".source = link_dotfiles "/tmux/.tmux.conf";
    ".shell_functions.sh".source = link_dotfiles "/zsh/.shell_functions.sh";
    ".config/nvim".source = link_dotfiles "/nvim";
    ".config/iterm2".source = link_dotfiles "/iterm2";
    ".config/yazi".source = link_dotfiles "/yazi";
    ".config/nix".source = link_dotfiles "/nix";
    ".config/nix-darwin".source = link_dotfiles "/nix/darwin";
    ".config/doom".source = link_dotfiles "/doom";
    "translate-romance-languages".source = link_dotfiles "/misc_projects/translate-romance-languages";
    # ".doom.d/init.el".source = link_dotfiles "/doom/init.el";
    # ".doom.d/config.el".source = link_dotfiles "/doom/config.el";
    # ".doom.d/packages.el".source = link_dotfiles "/doom/packages.el";
  };

  # home.sessionVariables =
  #   {
  #   };
  #
  # home.sessionPath = [
  #   "/run/current-system/sw/bin"
  #   "$HOME/.nix-profile/bin"
  # ];

  programs.git = {
    enable = true;
    extraConfig = {
      url = {
        "ssh://git@github.com/" = {
          insteadOf = "https://github.com/";
        };
      };
    };
  };
  #NOTE: testing
  # programs.zsh = {
  #   enable = true;
  #   syntaxHighlighting.enable = true;
  #   autosuggestion.enable = true;
  #   # enableSyntaxHighlighting = true;
  #   # enableAutosuggestions = true;
  #   # ohMyZsh = {
  #   #   enable = true;
  #   #   # plugins = [
  #   #   #   "git"
  #   #   #   "vi-mode"
  #   #   #   "zsh-autosuggestions"
  #   #   #   "zsh-syntax-highlighting"
  #   #   # ];
  #   #   theme = "robbyrussell";
  #   # };
  #   enableCompletion = true;
  #   completionInit = ''
  #     # Filter fpath to avoid broken/missing dirs
  #     fpath=(${"fpath:A"}(:aN))
  #
  #     # Run compinit safely
  #     autoload -Uz compinit && compinit -i
  #     zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
  #   '';
  #
  #   initExtra = ''
  #     mkdir -p $HOME/tmp
  #     echo "Home Manager managing Zsh" > $HOME/tmp/zsh-managed.log
  #     export DISABLE_AUTO_UPDATE=true
  #
  #
  #     # From your .zshrc
  #     setopt HIST_IGNORE_ALL_DUPS
  #     export PATH=/run/current-system/sw/bin:$HOME/.emacs.d/bin:$HOME/.nix-profile/bin:$PATH
  #
  #
  #     # Configure pure prompt
  #     fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
  #     autoload -U promptinit; promptinit
  #     prompt pure
  #   '';
  #
  # };
  programs.home-manager.enable = true;

}
