{
  description = "Nix Darwin system flake";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable/";
    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/";
      # url = "github:LnL7/nix-darwin/master"; # Use latest nix-darwin
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      self,
      home-manager,
      nix-darwin,
      nixpkgs,
    }:
    let
      username = "brightowl";
      hostname = "bright";
      hostPlatform = "aarch64-darwin";

      configuration =
        { pkgs, ... }:

        let
          # Helper function: 'pkg.meta.broken' is overridden to allow broken package
          unbreak =
            pkg:
            pkg.overrideAttrs (oldAttrs: {
              meta.broken = false;
            });

          cli = [
            pkgs.coreutils
            pkgs.bat
            pkgs.fd
            pkgs.fzf
            pkgs.eza
            pkgs.rename
            pkgs.ripgrep
            pkgs.tree
            pkgs.trash-cli
            (unbreak pkgs.jp2a)
            # pkgs.jq
            # pkgs.yq
          ];

          dev_tools = [
            pkgs.nodejs
            pkgs.math-preview
            #instead of 'npm install -g git+https://gitlab.com/matsievskiysv/math-preview' and change npm prefix .. due to nix immutability
            pkgs.git
            pkgs.gh
            pkgs.neovim
            # pkgs.nixd
            # pkgs.nil
            # (pkgs.symlinkJoin {
            #   name = "nil-with-options";
            #   paths = [ pkgs.nil ];
            #   buildInputs = [ pkgs.makeWrapper ];
            #   postBuild = ''
            #     wrapProgram $out/bin/nil \
            #       --set-default NIX_OPTIONS_JSON ${pkgs.nil}/lib/nil/nixpkgs/share/nix/options.json
            #   '';
            # })
            pkgs.nixfmt-rfc-style
            pkgs.shellcheck
            pkgs.shfmt
            pkgs.pandoc
            pkgs.htmlq
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

                #NOTE: running into issues building this  (need it for fasstext since langdetect is not robust)
                # (numpy.overridePythonAttrs (old: {
                #   version = "1.26.4";
                # })) # Pin to 1.26.4
              ]
            ))
          ];

          file_system = [ pkgs.fswatch ];

          media_tools = [
            pkgs.ffmpeg
            pkgs.ffmpegthumbnailer
            pkgs.imagemagick
            pkgs.mpv
            pkgs.pngpaste
            pkgs.sigtop
            pkgs.tesseract
            pkgs.vips
            pkgs.yt-dlp
            (pkgs.texlive.combine {
              inherit (pkgs.texlive)
                scheme-basic # Core LaTeX
                dvipng # PNG for Emacs preview
                dvisvgm # SVG option, useful for scalability
                amsmath # Math essentials
                amsfonts # Math fonts
                latex-bin # LaTeX commands
                ulem # without this doom emacs breaks when previewing latex?? might be better to use textlive scheme medium
                ; # Add more if needed (e.g., hyperref, geometry)
            })
            # pkgs.texlive.combined.scheme-medium
          ];

          networking = [
            pkgs.curl
            pkgs.htop
            pkgs.nghttp2
            pkgs.nmap
            pkgs.wget
          ];

          pdf_and_document = [
            pkgs.poppler
            pkgs.poppler_utils
            pkgs.viu
            pkgs.chafa
          ];

          system_utilities = [
            pkgs.blueutil
            pkgs.hello
            pkgs.rsync
          ];

          terminal_and_shell_enhancements = [
            pkgs.antidote
            pkgs.ast-grep # TEST: might remove this (also remove the wrapper in home.nix)
            pkgs.difftastic
            pkgs.fastfetch
            # pkgs.ghostty ## isnt supported??
            pkgs.iterm2
            pkgs.nushell
            pkgs.pure-prompt
            pkgs.yazi
            pkgs.tmux
          ];

          # __commented_out_pkgs = [
          #   pkgs.ghostscript # gs
          #   pkgs.haskellPackages.cabal-install
          #   pkgs.haskellPackages.haskell-language-server
          #   pkgs.haskellPackages.fourmolu
          #   pkgs.cabal-install # haskell
          #   pkgs.ghc # haskell
          #
          #   (pkgs.neovim.overrideAttrs (oldAttrs: {
          #     version = "0.11.0-dev-1265+g6cdcac4492";
          #     src = pkgs.fetchFromGitHub {
          #       owner = "neovim";
          #       repo = "neovim";
          #       rev = "6cdcac4492"; # The commit hash
          #       sha256 = "0m8fki6mv71gzq14xx8h41cgs1kbr7vws523p59nszfc52sshps3"; # The new hash you obtained
          #     };
          #   }))
          #   pkgs.glib
          #   pkgs.parallel
          #   pkgs.unbound
          #   pkgs.zig
          # ];
        in
        {
          # >>>  PUT THE OPTIONS HERE  <<<
          # <-- added oct 10-2025
          system.primaryUser = username;
          programs.zsh.enable = false;

          # <-- added oct 10-2025

          # security.pam.enableSudoTouchIdAuth = true;
          security.pam.services.sudo_local.touchIdAuth = true;
          # users.knownUsers = [ username ]; NOTE: was supposed to delete
          environment.pathsToLink = [
            "/bin"
            "/share"
          ];
          environment.systemPackages =
            cli
            ++ dev_tools
            ++ file_system
            ++ media_tools
            ++ networking
            ++ pdf_and_document
            ++ system_utilities
            ++ terminal_and_shell_enhancements;

          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = false; # Avoid auto-updating during activation
              # cleanup = "zap"; # Remove unlisted formulae/casks
              # cleanup = "uninstall"; # Remove unlisted formulae/casks #NOTE: currently headache error message
              cleanup = "none";
            };
            casks = [
              "ghostty@tip"
              "brave-browser"
              # "discord"
              # "firefox"
              "gimp"
              # "google-chrome"
              "hammerspoon"
              "iina"
              # "imageoptim"
              "keka"
              "krita"
              "shottr"
              # "sublime-text"
              # "alfred"
              # "alfred@4"
              # "rectangle"
              # "rectangle-pro"
              # "railwaycat/emacsmacport/emacs-mac"
            ];
            taps = [
              "d12frosted/emacs-plus"
              # "railwaycat/emacsmacport" # For macOS-optimized Emacs
            ];

            brews = [
              "mas"
              # {
              #   name = "emacs-plus@30";
              #   options = [ "with-xwidgets" ];
              # }
              {
                # name = "emacs-plus@30";
                name = "emacs-plus@30";
                args = [
                  "with-xwidgets"
                  # "with-native-comp" #not valid in @30
                  # "with-modern-doom3-icon"
                ];
              }
              "libgccjit" # Required for native compilation
            ];

            masApps = {
              AdvancedScreenShare = 1597458111;
              DemoPro = 1384206666;
              # HiddenBar = 1452453066;
              # Notability = 360593530;
              OneThing = 1604176982;
              # PerplexityAI = 6714467650;
              # SystemColorPicker = 1545870783;
            };

          };

          home-manager.backupFileExtension = "backup";

          # # this required otherwise home.nix breaks build until i use lib.mkForce prefix on homeDirectory
          users.users.${username} = {
            name = username;
            home = "/Users/${username}";

            shell = pkgs.zsh;
            ignoreShellProgramCheck = true;

            ## NOTE: are these needed anymore?
            # uid = 501;
          };

          #NOTE:  apparently this is not needed in latest flake update
          # services.nix-daemon.enable = true;

          nix.package = pkgs.nix;
          nix.settings.experimental-features = "nix-command flakes";
          # nix.settings = {
          #   experimental-features = "nix-command flakes";
          #
          #   #allegedly below will make build speeds faster since using all cores on my mac??
          #   #  # NOTE: remove
          #   # cores = 0;
          #   # max-jobs = "auto";
          #   # sandbox = false; # Optional: Speeds up local builds if you trust your env
          #   # # ... any other settings you had
          # };

          nix.optimise.automatic = true; # Dedupes store paths safely post-build; NOTE: remove

          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 5;
          nixpkgs.hostPlatform = hostPlatform;

          system.defaults = {
            universalaccess.reduceMotion = true;
            NSGlobalDomain = {
              InitialKeyRepeat = 15;
              KeyRepeat = 2;
            };
            dock = {
              autohide = true;
              mru-spaces = false;
            };
            finder = {
              AppleShowAllExtensions = true;
              FXPreferredViewStyle = "clmv";
            };
            screencapture.location = "~/screenshots";
            screensaver.askForPasswordDelay = 10;
            loginwindow.LoginwindowText = "kalimba";
          };
        };
    in
    {

      # formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;

      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        system = hostPlatform;
        modules = [
          configuration

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            # home-manager.useUserPackages = true;
            home-manager.useUserPackages = false; # TEST: test
            home-manager.users.${username} = {
              imports = [ ./home.nix ];
            };
            # home-manager.users.${username} = import ./home.nix;
            home-manager.extraSpecialArgs = {
              inherit username;
            };

          }
        ];
      };

      darwinPackages = self.darwinConfigurations.${hostname}.pkgs;
    };
}
