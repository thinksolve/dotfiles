{
  description = "Nix Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable/";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
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
          environment.systemPackages = [

            (unbreak pkgs.jp2a)
            pkgs.curl
            pkgs.fastfetch
            pkgs.fd
            pkgs.ffmpeg
            pkgs.ffmpegthumbnailer
            pkgs.fzf
            pkgs.gh
            pkgs.ghostscript # gs
            pkgs.git
            pkgs.htop
            pkgs.imagemagick # magick (convert, identify)
            pkgs.iterm2
            pkgs.jq
            pkgs.neovim # nvim
            pkgs.nghttp2
            pkgs.nixd
            pkgs.nixfmt-rfc-style
            pkgs.nmap
            pkgs.pandoc
            pkgs.poppler
            pkgs.rename
            pkgs.ripgrep # rg
            pkgs.rsync
            pkgs.shellcheck
            pkgs.shfmt
            pkgs.tree
            pkgs.wget
            pkgs.yazi
            pkgs.zig
            # pkgs.poppler_utils
            # pkgs.yq
            # pkgs.tesseract
            # pkgs.unbound
            # pkgs.glib
          ];

          homebrew = {
            enable = true;
            casks = [
              "brave-browser"
              "discord"
              "firefox"
              "gimp"
              "google-chrome"
              "hammerspoon"
              "iina"
              "imageoptim"
              "keka"
              "krita"
              "shottr"
              "sublime-text"
              # "alfred"
              # "alfred@4"
              # "rectangle"
              # "rectangle-pro"
            ];
            # taps =
            #   [
            #   ];
            brews = [ "mas" ];
            masApps = {
              AdvancedScreenShare = 1597458111;
              DemoPro = 1384206666;
              HiddenBar = 1452453066;
              Notability = 360593530;
              OneThing = 1604176982;
              SystemColorPicker = 1545870783;
            };

          };

          home-manager.backupFileExtension = "backup";

          # this required otherwise home.nix breaks build until i use lib.mkForce prefix on homeDirectory
          users.users.${username} = {
            name = username;
            home = "/Users/${username}";
            shell = pkgs.zsh;
          };
          services.nix-daemon.enable = true;
          nix.package = pkgs.nix;
          nix.settings.experimental-features = "nix-command flakes";
          programs.zsh.enable = true;
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 5;
          nixpkgs.hostPlatform = hostPlatform;

          # NOTE: ... install script said to add this since a previous install had other nixbld users?
          nix.configureBuildUsers = true;

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
            # loginwindow.LoginwindowText = "kalimba";
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
