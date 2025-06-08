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

      # Helper function: 'pkg.meta.broken' is overridden to allow broken package
      unbreak =
        pkg:
        pkg.overrideAttrs (oldAttrs: {
          meta.broken = false;
        });

      configuration =
        { pkgs, ... }:
        {
          # security.pam.enableSudoTouchIdAuth = true;
          security.pam.services.sudo_local.touchIdAuth = true;
          # users.knownUsers = [ username ]; NOTE: was supposed to delete
          environment.systemPackages = [

            # ---- CLI Utilities ----
            pkgs.bat
            pkgs.fd
            pkgs.fzf
            pkgs.rename
            pkgs.ripgrep
            pkgs.tree
            (unbreak pkgs.jp2a)
            # pkgs.jq
            # pkgs.yq

            # ---- Networking ----
            pkgs.curl
            pkgs.htop
            pkgs.nghttp2
            pkgs.nmap
            pkgs.wget

            # ---- Media Tools ----
            pkgs.ffmpeg
            pkgs.ffmpegthumbnailer
            pkgs.imagemagick
            pkgs.pngpaste
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

            # ---- Development Tools ----
            pkgs.nodejs
            pkgs.git
            pkgs.gh
            pkgs.neovim
            pkgs.nixd
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

            # ---- PDF and Document Processing ----
            pkgs.poppler
            pkgs.poppler_utils

            # ---- Terminal and Shell Enhancements ----
            pkgs.fastfetch
            pkgs.iterm2
            pkgs.pure-prompt
            pkgs.yazi
            # pkgs.tmux

            # ---- System Utilities ----
            pkgs.blueutil
            pkgs.hello
            pkgs.rsync

            # pkgs.ghostscript # gs
            # pkgs.haskellPackages.cabal-install
            # pkgs.haskellPackages.haskell-language-server
            # pkgs.haskellPackages.fourmolu
            # pkgs.cabal-install # haskell
            # pkgs.ghc # haskell

            # (pkgs.neovim.overrideAttrs (oldAttrs: {
            #   version = "0.11.0-dev-1265+g6cdcac4492";
            #   src = pkgs.fetchFromGitHub {
            #     owner = "neovim";
            #     repo = "neovim";
            #     rev = "6cdcac4492"; # The commit hash
            #     sha256 = "0m8fki6mv71gzq14xx8h41cgs1kbr7vws523p59nszfc52sshps3"; # The new hash you obtained
            #   };
            # }))
            # pkgs.glib
            # pkgs.oh-my-zsh
            # pkgs.parallel
            # pkgs.unbound
            # pkgs.zig
            # pkgs.zsh-autosuggestions
            # pkgs.zsh-syntax-highlighting
          ];

          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = false; # Avoid auto-updating during activation
              # cleanup = "zap"; # Remove unlisted formulae/casks
              cleanup = "uninstall"; # Remove unlisted formulae/casks
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

          # this required otherwise home.nix breaks build until i use lib.mkForce prefix on homeDirectory
          users.users.${username} = {
            name = username;
            home = "/Users/${username}";
            shell = pkgs.zsh;
            uid = 501;
          };

          #NOTE:  apparently this is not needed in latest flake update
          # services.nix-daemon.enable = true;

          nix.package = pkgs.nix;
          nix.settings.experimental-features = "nix-command flakes";
          programs.zsh.enable = true;
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
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home.nix;
            home-manager.extraSpecialArgs = {
              inherit username;
            };

          }
        ];
      };

      darwinPackages = self.darwinConfigurations.${hostname}.pkgs;
    };
}
