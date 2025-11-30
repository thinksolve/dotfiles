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

  # Helper function: 'pkg.meta.broken' is overridden to allow broken package
  unbreak =
    pkg:
    pkg.overrideAttrs (oldAttrs: {
      meta.broken = false;
    });

  cli = [
    pkgs.bat
    pkgs.coreutils
    pkgs.eza
    pkgs.fd
    pkgs.fzf
    pkgs.rename
    pkgs.ripgrep
    pkgs.trash-cli
    pkgs.tree
    (unbreak pkgs.jp2a)
    # pkgs.jq
    # pkgs.yq
  ];

  dev_tools = [
    pkgs.gh
    pkgs.git
    # pkgs.lua5_4
    # pkgs.lua54Packages.luasocket
    pkgs.htmlq
    # pkgs.math-preview # instead of 'npm install -g git+https://gitlab.com/matsievskiysv/math-preview' and change npm prefix .. due to nix immutability
    pkgs.neovim
    pkgs.nixfmt-rfc-style
    # pkgs.nodejs
    # pkgs.pandoc
    # pkgs.shellcheck
    pkgs.shfmt
    # pkgs.helix
    (pkgs.python3.withPackages (
      ps: with ps; [
        fastapi
        sacremoses
        sentencepiece
        torch
        transformers
        uvicorn
        langdetect
        fasttext
      ]
    ))
  ];

  file_system = [ pkgs.fswatch ];
  pdf_and_document = [
    pkgs.chafa
    # pkgs.poppler #not needed when moved from flake.nix to home.nix?
    pkgs.poppler-utils
    # pkgs.viu
  ];

  terminal_and_shell_enhancements = [
    pkgs.antidote
    pkgs.carapace
    pkgs.difftastic
    pkgs.fastfetch
    # pkgs.ghostty ## isnt supported??
    # pkgs.iterm2
    pkgs.kitty
    # pkgs.tmux
    pkgs.tldr
    pkgs.yazi
  ];
in
{
  home.username = "brightowl";
  home.homeDirectory = "/Users/brightowl";
  # home.username = lib.mkForce username;
  # home.homeDirectory = lib.mkForce "/Users/${username}";

  # home.username = username;
  # home.homeDirectory = "/Users/${username}";  <-- commented out oct 2025

  # home.homeDirectory = "/Users/${config.home.username}";
  # home.homeDirectory = lib.mkForce "/Users/brightowl";
  # home.stateVersion = "24.11";
  home.stateVersion = "23.11";

  home.packages =
    cli ++ dev_tools ++ file_system ++ pdf_and_document ++ terminal_and_shell_enhancements;

  # home.activation.build-zshrc-flat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   cat \
  #     ${./zsh/aliases} \
  #     ${./zsh/exports} \
  #      > $HOME/.zshrc_flat_test
  # '';

  home.file = {
    ".local/bin/sg" = {
      text = ''
        #!/usr/bin/env bash
        exec ${pkgs.ast-grep}/bin/ast-grep "$@"
      '';
      executable = true;
    };
    "/Library/Application Support/com.mitchellh.ghostty/config".source =
      link_dotfiles "/ghostty/config";

    ".local/bin/recent-open".source = link_dotfiles "/bin/recent-open";
    # ".local/bin/log-and-run" = {
    #   source = link_dotfiles "/bin/log-and-run";
    #   # source = ./../../bin/log-and-run;
    #   executable = true;
    # };

    ".local/bin/nvim".source = link_dotfiles "/bin/nvim-recent";
    # ".local/bin/nvim" = {
    #   source = link_dotfiles "/bin/nvim-recent";
    #   executable = true;
    # };

    ".local/bin/yt-txt".source = link_dotfiles "/bin/yt-txt";
    # ".local/bin/yt-txt" = {
    #   source = link_dotfiles "/bin/yt-txt";
    #   executable = true;
    # };
    ".hammerspoon".source = link_dotfiles "/hammerspoon";
    ".config/path.sh".source = link_dotfiles "/zsh/path.sh";
    ".config/zsh/aliases.zsh".source = link_dotfiles "/zsh/aliases.zsh";
    ".config/zsh/bindkeys.zsh".source = link_dotfiles "/zsh/bindkeys.zsh";
    ".config/zsh/constants.zsh".source = link_dotfiles "/zsh/constants.zsh";
    ".config/zsh/preferences.zsh".source = link_dotfiles "/zsh/preferences.zsh";
    ".config/zsh/terminal_styling.zsh".source = link_dotfiles "/zsh/terminal_styling.zsh";
    ".zshrc".source = link_dotfiles "/zsh/.zshrc";
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
  home.activation.zcompile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.zsh}/bin/zsh -c '
      [[ -f $HOME/.zshrc ]] && zcompile -Uz $HOME/.zshrc
    '
  '';

  # home.sessionVariables =
  #   {
  #   };
  #
  home.sessionPath = [
    "/run/current-system/sw/bin"
    "$HOME/.nix-profile/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];

  programs.git = {
    enable = true;
    settings = {
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
