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

  # maps repettive files and diretory structures
  outOfStoreLinks =
    targetDir: sourceDir: entries:
    builtins.listToAttrs (
      map (entry: {
        name = "${targetDir}/${entry}";
        value.source = config.lib.file.mkOutOfStoreSymlink "${sourceDir}/${entry}";
      }) entries
    );

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

  home.stateVersion = "23.11";

  home.packages =
    cli ++ dev_tools ++ file_system ++ pdf_and_document ++ terminal_and_shell_enhancements;

  # home.activation.build-zshrc-flat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   cat \
  #     ${./zsh/aliases} \
  #     ${./zsh/exports} \
  #      > $HOME/.zshrc_flat_test
  # '';

  home.file =
    (outOfStoreLinks ".config/zsh" "${dotfiles_dir}/zsh" [
      "after_compinit.zsh"
      "aliases.zsh"
      "bindkeys.zsh"
      "constants.zsh"
      "fast_compinit.zsh"
      "path.sh"
      "preferences.zsh"
      "terminal_styling.zsh"
    ])
    // (outOfStoreLinks ".local/bin" "${dotfiles_dir}/bin" [
      "recent"
      "nvim"
      "yt-txt"
    ])
    // (outOfStoreLinks ".config/" "${dotfiles_dir}/" [
      "doom"
      "ghostty"
      "iterm2"
      "nix"
      "nvim"
      "yazi"
    ])
    // {
      ".config/nix-darwin".source = link_dotfiles "/nix/darwin";
      ".hammerspoon".source = link_dotfiles "/hammerspoon";
      ".shell_functions.sh".source = link_dotfiles "/zsh/.shell_functions.sh";
      ".tmux.conf".source = link_dotfiles "/tmux/.tmux.conf";
      ".zsh_plugins.txt".source = link_dotfiles "/zsh/.zsh_plugins.txt";
      ".zshrc".source = link_dotfiles "/zsh/.zshrc";
      "translate-romance-languages".source = link_dotfiles "/misc_projects/translate-romance-languages";
      # ".doom.d/init.el".source = link_dotfiles "/doom/init.el";
      # ".doom.d/config.el".source = link_dotfiles "/doom/config.el";
      # ".doom.d/packages.el".source = link_dotfiles "/doom/packages.el";
      ".local/bin/sg" = {
        text = ''
          #!/usr/bin/env bash
          exec ${pkgs.ast-grep}/bin/ast-grep "$@"
        '';
        executable = true;
      };
      "/Library/Application Support/com.mitchellh.ghostty/config".source =
        link_dotfiles "/ghostty/config";

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
