#~/.dotfiles/nix/darwin/home.nix

{
  config,
  pkgs,
  username,
  # lib,
  ...
}:
{
  home.username = "brightowl";
  home.homeDirectory = "/Users/brightowl";
  home.stateVersion = "23.11";
  # home.sessionPath = [
  #   "/run/current-system/sw/bin"
  #   "$HOME/.nix-profile/bin"
  #   "${config.home.homeDirectory}/.local/bin"
  # ];

  # home.activation.zcompile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   ${pkgs.zsh}/bin/zsh -c '
  #     [[ -f $HOME/.zshrc ]] && zcompile -Uz $HOME/.zshrc
  #   '
  # '';
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

  programs.home-manager.enable = true;

  home.file =
    let
      dotfiles_dir = "${config.home.homeDirectory}/.dotfiles";
      dotfiles = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles_dir}/${path}";

      # Makes bearable symlinking many (but not all) items with identical basenames (generally relative paths!).
      # e.g. "${symPrefix}/${basename}".source = config.lib.file.mkOutOfStoreSymlink "${targetPrefix}/${basename}"
      outOfStoreLinks =
        symPrefix: targetPrefix: relPaths:
        builtins.listToAttrs (
          map (relPath: {
            name = "${symPrefix}/${relPath}";
            value.source = config.lib.file.mkOutOfStoreSymlink "${targetPrefix}/${relPath}";
          }) relPaths
        );

      # For each base in bases:
      #   Creates: symlink at "${symlinkPrefix}/${base}${suffix}"
      #   Points to: "${targetPrefix}/${base}"
      affixLinks =
        symlinkPrefix: targetPrefix: options: basenames:
        let
          symSuffix = options.sym_suffix or ""; # symPrefix = options.sym_prefix or ""; WIP ..
        in
        builtins.listToAttrs (
          map (basename: {
            name = "${symlinkPrefix}/${basename}${symSuffix}";
            value.source = config.lib.file.mkOutOfStoreSymlink "${targetPrefix}/${basename}";
          }) basenames
        );
    in
    {
      ".config/nix-darwin".source = dotfiles "/nix/darwin";
      ".hammerspoon".source = dotfiles "/hammerspoon";
      ".shell_functions.sh".source = dotfiles "/zsh/.shell_functions.sh";
      ".tmux.conf".source = dotfiles "/tmux/.tmux.conf";
      ".zsh_plugins.txt".source = dotfiles "/zsh/.zsh_plugins.txt";
      ".zshrc".source = dotfiles "/zsh/.zshrc";
      "/Library/Application Support/com.mitchellh.ghostty/config".source = dotfiles "/ghostty/config";
      # ".doom.d/init.el".source = dotfiles "/doom/init.el";
      # ".doom.d/config.el".source = dotfiles "/doom/config.el";
      # ".doom.d/packages.el".source = dotfiles "/doom/packages.el";
      "translate-romance-languages".source = dotfiles "/misc_projects/translate-romance-languages";
    }

    // (outOfStoreLinks ".local/" "${dotfiles_dir}/" [
      "bin/recent"
      "bin/yt-txt"
    ])
    // (outOfStoreLinks ".config/" "${dotfiles_dir}/" [
      "doom"
      "ghostty"
      "iterm2"
      "nix"
      "nvim"
      "yazi"
      "zsh/after_compinit.zsh"
      "zsh/aliases.zsh"
      "zsh/bindkeys.zsh"
      "zsh/constants.zsh"
      "zsh/fast_compinit.zsh"
      "zsh/preferences.zsh"
      "zsh/terminal_styling.zsh"
    ])
    // (affixLinks ".dotfiles/ghostty/themes"
      "/Applications/Ghostty.app/Contents/Resources/ghostty/themes/"
      { sym_suffix = ".light"; }
      [
        "Adwaita"
      ]
    )
    // (affixLinks ".dotfiles/ghostty/themes"
      "/Applications/Ghostty.app/Contents/Resources/ghostty/themes/"
      { sym_suffix = ".dark"; }
      [
        "Afterglow"
        "Dracula"
        "Nord"
        "rose-pine"
      ]
    );

  home.packages =
    let
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
    cli ++ dev_tools ++ file_system ++ pdf_and_document ++ terminal_and_shell_enhancements;

  # home.sessionVariables =
  #   {
  #   };
  #
}
