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

  # programs.direnv = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   nix-direnv.enable = true;
  # };
  # # #TEST:

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
      # fileToList_0 = file: lib.filter (s: s != "") (lib.splitString "\n" (builtins.readFile file));
      #
      # #same as   fileToList_0  but filters commented lines with comment character '#'
      # fileToList_1 =
      #   file:
      #   map lib.trim (
      #     lib.filter (s: s != "") (
      #       map (line: lib.head (lib.splitString "#" line)) (lib.splitString "\n" (builtins.readFile file))
      #     )
      #   );

      # using pipe syntax ot make all the nesting easer to read
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

  home.activation.generateZshrc =
    let
      outputFile = "${config.home.homeDirectory}/.dotfiles/zsh/.zshrc";
      zshrcBody = ''
        export ZSH_CONFIG="$HOME/.dotfiles/zsh"
        export ANTIDOTE_PATH="${pkgs.antidote}/share/antidote/antidote.zsh"

        source $ZSH_CONFIG/constants.zsh
        source $ZSH_CONFIG/.shell_functions.sh
        source $ZSH_CONFIG/aliases.zsh
        source $ZSH_CONFIG/bindkeys.zsh
        source $ZSH_CONFIG/preferences.zsh
        source $ZSH_CONFIG/terminal_styling.zsh
        source $ZSH_CONFIG/fast_compinit.zsh
        source $ZSH_CONFIG/after_compinit.zsh

        _plugins_zsh=$HOME/.zsh_plugins.zsh
        _plugins_txt=$HOME/.zsh_plugins.txt

        if [[ -f $_plugins_txt && ( ! -f $_plugins_zsh || $_plugins_txt -nt $_plugins_zsh ) ]]; then
            echo 'sourcing plugins txt file'
            source $ANTIDOTE_PATH
            antidote load
        elif [[ -f $_plugins_zsh ]]; then
            source $_plugins_zsh
        fi

        do_exit_cleanup() {
            fzd.cleanup
        }

        trap do_exit_cleanup EXIT
      '';
    in
    # lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    lib.hm.dag.entryBefore [ "linkGeneration" ] ''

      $DRY_RUN_CMD cat > ${outputFile} << 'EOF'

      # ╔════════════════════════════════════════════════════════════════╗
      # ║  AUTO-GENERATED by Nix (home.activation.generateZshrc)         ║
      # ║  Ephemeral: edits lost on `darwin-rebuild switch`              ║
      # ║  Source of truth: ~/.dotfiles/nix/darwin/home.nix              ║
      # ╚════════════════════════════════════════════════════════════════╝

      ${zshrcBody} 
      EOF
      $DRY_RUN_CMD chmod +w ${outputFile}
      run echo "Test activation script completed - check ${outputFile}"
    '';

  home.activation.generateZshenv =
    let
      outputFile = "${config.home.homeDirectory}/.dotfiles/zsh/.zshenv";
      zshenvBody = ''
        export PNPM_HOME=$HOME/Library/pnpm
        export NIX_CURRENT_SYSTEM_BIN=/run/current-system/sw/bin
        export NIX_CURRENT_USER_BIN=$HOME/.nix-profile/bin
        export HM_PROFILE="$HOME/.local/state/nix/profiles/home-manager"
        export HOMEBREW_BIN="/opt/homebrew/bin"

        export PATH="$HM_PROFILE/bin:$NIX_CURRENT_SYSTEM_BIN:$NIX_CURRENT_USER_BIN:$HOME/.local/bin:$HOME/.config/emacs/bin:$HOME/bin:/usr/local/bin:$PNPM_HOME:$HOMEBREW_BIN:$PATH"
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

      $DRY_RUN_CMD chmod +w ${outputFile}
      run echo "Test activation script completed - check ${outputFile}"
    '';

}
