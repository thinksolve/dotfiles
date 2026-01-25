# ~/.dotfiles/nix/darwin/home.nix
{
  config,
  pkgs,
  username,
  lib,
  ...
}:
{
  home.username = "brightowl";
  home.homeDirectory = "/Users/brightowl";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  # programs.direnv = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   nix-direnv.enable = true;
  # };

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

  home.file =
    let
      dotfiles_dir = "${config.home.homeDirectory}/.dotfiles";
      dotfiles = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles_dir}/${path}";
      from_home = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${path}";

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
      #   Creates: symlink at "${symPrefix}/${base}${suffix}"
      #   Points to: "${targetPrefix}/${base}"
      affixLinks =
        symPrefix: targetPrefix: options: basenames:
        let
          symSuffix = options.sym_suffix or ""; # symPrefix = options.sym_prefix or ""; WIP ..
        in
        builtins.listToAttrs (
          map (basename: {
            name = "${symPrefix}/${basename}${symSuffix}";
            value.source = config.lib.file.mkOutOfStoreSymlink "${targetPrefix}/${basename}";
          }) basenames
        );

      # #useful for converting a newline separated txt file into a nix list of quoted elements
      # fileToList = file: lib.filter (s: s != "") (lib.splitString "\n" (builtins.readFile file));

      # filter out comments; using pipe syntax to make all the nesting easer to read
      fileToList =
        file:
        lib.pipe file [
          builtins.readFile
          (lib.splitString "\n")
          (map (l: lib.head (lib.splitString "#" l)))
          (lib.filter (s: s != ""))
          (map lib.trim)
        ];

    in
    {
      # ".local/bin/teal-language-server".source = from_home "/.luarocks/bin/teal-language-server"; #might remove along with ~/teal-language-server/ and ~/.dotfiles/dev/lua
      ".config/nix-darwin".source = dotfiles "/nix/darwin";
      ".hammerspoon".source = dotfiles "/hammerspoon";
      ".shell_functions.sh".source = dotfiles "/zsh/.shell_functions.sh";
      ".tmux.conf".source = dotfiles "/tmux/.tmux.conf";
      ".zsh_plugins.txt".source = dotfiles "/zsh/.zsh_plugins.txt";
      ".zshrc".source = dotfiles "/zsh/.zshrc";
      ".zshenv".source = dotfiles "/zsh/.zshenv";

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
      "s"
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
      (fileToList ../../ghostty/ghostty-themes-light)
    )
    // (affixLinks ".dotfiles/ghostty/themes"
      "/Applications/Ghostty.app/Contents/Resources/ghostty/themes/"
      { sym_suffix = ".dark"; }
      (fileToList ../../ghostty/ghostty-themes-dark)
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
        # pkgs.lua54Packages.luarocks
        # pkgs.nodejs_22 # when trying to open tl files in nvim its complaining i dont have node
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
  # home.sessionPath = [
  # ];

  #NOTE: decided against generating zshrc as well; zshenv can export nix specific paths from the generated zshenv
  home.activation.generateZshenv =
    let
      outputFile = "${config.home.homeDirectory}/.dotfiles/zsh/.zshenv";
      zshenvBody = ''
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
        export ANTIDOTE_PATH="${pkgs.antidote}/share/antidote/antidote.zsh"
        export REAL_NVIM="${pkgs.neovim}/bin/nvim"

        # PATH
        export PATH="$HM_PROFILE/bin:$NIX_CURRENT_SYSTEM/bin:$NIX_CURRENT_USER/bin:$HOME/.local/bin:$HOME/.config/emacs/bin:$HOME/bin:/usr/local/bin:$PNPM_HOME:$HOMEBREW_BIN:$PATH"
      '';
    in
    lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      $DRY_RUN_CMD cat > ${outputFile} << 'EOF'
      # ╔════════════════════════════════════════════════════════════════╗
      # ║  AUTO-GENERATED by Nix (home.activation.generateZshenv)        ║
      # ║  Ephemeral: edits lost on `darwin-rebuild switch`              ║
      # ║  Source of truth: ~/.dotfiles/nix/darwin/home.nix              ║
      # ╚════════════════════════════════════════════════════════════════╝

      ${zshenvBody}
      EOF

      run echo "Test activation script completed - check ${outputFile}"
    '';
  #$DRY_RUN_CMD chmod +w ${outputFile}
}
