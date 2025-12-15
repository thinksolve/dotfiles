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
        "Alabaster"
        "CLRS"
        "coffee_theme"
        "Github"
        "Havn Daggry"
        "Horizon-Bright"
        "Man Page"
        "Material"
        "Novel"
        "primary"
        "Spring"
        "Tango Adapted"
        "Tango Half Adapted"
        "Terminal Basic"
        "Tomorrow"
        "Unikitty"
        "vimbones"
        "zenbones"
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
        "Aardvark Blue"
        "Abernathy"
        "Adventure"
        "AdventureTime"
        "AlienBlood"
        "Andromeda"
        "Apple Classic"
        "Apple System Colors"
        "arcoiris"
        "Ardoise"
        "Argonaut"
        "Arthur"
        "AtelierSulphurpool"
        "Atom"
        "Aura"
        "Aurora"
        "ayu"
        "Ayu Mirage"
        "Banana Blueberry"
        "Batman"
        "BirdsOfParadise"
        "Blazer"
        "Blue Matrix"
        "BlueBerryPie"
        "BlueDolphin"
        "Borland"
        "Breeze"
        "Broadcast"
        "Brogrammer"
        "C64"
        "Calamity"
        "carbonfox"
        "CGA"
        "Chalk"
        "Chalkboard"
        "ChallengerDeep"
        "Chester"
        "Ciapre"
        "citruszest"
        "Cobalt Neon"
        "Cobalt2"
        "CobaltNext"
        "CobaltNext-Minimal"
        "CrayonPonyFish"
        "CutiePro"
        "Cyberdyne"
        "cyberpunk"
        "CyberpunkScarletProtocol"
        "deep"
        "Desert"
        "detuned"
        "Dimidium"
        "DimmedMonokai"
        "Django"
        "DjangoRebornAgain"
        "DjangoSmooth"
        "Doom Peacock"
        "DoomOne"
        "DotGov"
        "Dracula"
        "Dracula+"
        "duckbones"
        "duskfox"
        "Earthsong"
        "Elegant"
        "Elemental"
        "Elementary"
        "Embark"
        "ENCOM"
        "Espresso"
        "Espresso Libre"
        "Everblush"
        "Fahrenheit"
        "Fairyfloss"
        "Fideloper"
        "Firefly Traditional"
        "FirefoxDev"
        "Firewatch"
        "FishTank"
        "Flat"
        "Flatland"
        "Floraverse"
        "ForestBlue"
        "Framer"
        "FunForrest"
        "Galaxy"
        "Galizur"
        "Glacier"
        "Grape"
        "Grass"
        "Grey-green"
        "gruvbox-material"
        "Guezwhoz"
        "Hacktober"
        "Hardcore"
        "Harper"
        "Havn Skumring"
        "HaX0R_BLUE"
        "HaX0R_GR33N"
        "HaX0R_R3D"
        "heeler"
        "Highway"
        "Hipster Green"
        "Hivacruz"
        "Homebrew"
        "Hopscotch"
        "Hopscotch.256"
        "Horizon"
        "Hurtado"
        "Hybrid"
        "IC_Green_PPL"
        "IC_Orange_PPL"
        "idea"
        "idleToes"
        "IRIX Console"
        "IRIX Terminal"
        "iTerm2 Default"
        "iTerm2 Smoooooth"
        "Jackie Brown"
        "Japanesque"
        "Jellybeans"
        "JetBrains Darcula"
        "jubi"
        "Kanagawa Dragon"
        "Kanagawa Wave"
        "kanagawabones"
        "Kibble"
        "Kolorit"
        "Konsolas"
        "kurokula"
        "Lab Fox"
        "Laser"
        "Later This Evening"
        "Lavandula"
        "LiquidCarbon"
        "LiquidCarbonTransparent"
        "LiquidCarbonTransparentInverse"
        "lovelace"
        "Mariana"
        "MaterialDesignColors"
        "MaterialOcean"
        "Mathias"
        "matrix"
        "Medallion"
        "Mellifluous"
        "mellow"
        "miasma"
        "Mirage"
        "Misterioso"
        "Molokai"
        "MonaLisa"
        "Monokai Classic"
        "Monokai Pro"
        "Monokai Pro Machine"
        "Monokai Pro Octagon"
        "Monokai Pro Ristretto"
        "Monokai Pro Spectrum"
        "Monokai Remastered"
        "Monokai Soda"
        "Monokai Vivid"
        "N0tch2k"
        "Neon"
        "Neopolitan"
        "Neutron"
        "niji"
        "nord"
        "nord-wave"
        "nordfox"
        "Ocean"
        "Oceanic-Next"
        "OceanicMaterial"
        "Ollie"
        "Oxocarbon"
        "Pandora"
        "PaulMillr"
        "Peppermint"
        "Pnevma"
        "Popping and Locking"
        "Pro"
        "Purple Rain"
        "purplepeter"
        "Rapture"
        "rebecca"
        "Red Alert"
        "Red Planet"
        "Red Sands"
        "Relaxed"
        "Retro"
        "RetroLegends"
        "Rippedcasts"
        "rose-pine"
        "Rouge 2"
        "Royal"
        "Ryuuko"
        "Sakura"
        "Scarlet Protocol"
        "Seafoam Pastel"
        "SeaShells"
        "Seti"
        "shades-of-purple"
        "Shaman"
        "Slate"
        "SleepyHollow"
        "Smyck"
        "Snazzy"
        "Snazzy Soft"
        "SoftServer"
        "Solarized Darcula"
        "sonokai"
        "Spacedust"
        "SpaceGray"
        "SpaceGray Bright"
        "SpaceGray Eighties"
        "SpaceGray Eighties Dull"
        "Spiderman"
        "Square"
        "srcery"
        "Sublette"
        "Subliminal"
        "Sugarplum"
        "Sundried"
        "Symfonic"
        "synthwave"
        "synthwave-everything"
        "SynthwaveAlpha"
        "Teerb"
        "terafox"
        "Thayer Bright"
        "The Hulk"
        "ToyChest"
        "Treehouse"
        "Ubuntu"
        "UltraViolent"
        "UnderTheSea"
        "Urple"
        "Vaughn"
        "Vesper"
        "VibrantInk"
        "WarmNeon"
        "Wez"
        "Whimsy"
        "WildCherry"
        "wilmersdorf"
        "Wombat"
        "Wryan"
        "xcodewwdc"
        "Zenburn"
        "zenburned"

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
