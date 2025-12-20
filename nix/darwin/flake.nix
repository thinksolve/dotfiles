#~/.dotfiles/nix/darwin/flake.nix

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
        {
          system.primaryUser = username;
          programs.zsh.enable = false;

          security.pam.services.sudo_local.touchIdAuth = true;
          environment.pathsToLink = [
            "/bin"
            "/share"
          ];
          environment.systemPackages =
            let
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
                # (pkgs.texlive.combine {
                #   inherit (pkgs.texlive)
                #     scheme-basic # Core LaTeX
                #     dvipng # PNG for Emacs preview
                #     dvisvgm # SVG option, useful for scalability
                #     amsmath # Math essentials
                #     amsfonts # Math fonts
                #     latex-bin # LaTeX commands
                #     ulem # without this doom emacs breaks when previewing latex?? might be better to use textlive scheme medium
                #     ; # Add more if needed (e.g., hyperref, geometry)
                # })
                ## pkgs.texlive.combined.scheme-medium
              ];

              networking = [
                pkgs.curl
                pkgs.htop
                pkgs.nghttp2
                pkgs.nmap
                pkgs.wget
              ];

              system_utilities = [
                pkgs.blueutil
                pkgs.hello
                pkgs.rsync
              ];

            in
            media_tools ++ networking ++ system_utilities;

          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = false; # Avoid auto-updating during activation
              cleanup = "none";
            };
            casks = [
              "ghostty@tip"
              "brave-browser"
              "gimp"
              "hammerspoon"
              "iina"
              "keka"
              "krita"
              "shottr"

            ];
            taps = [
              "d12frosted/emacs-plus"
            ];

            brews = [
              "s-search"
              "mas"
              {
                name = "emacs-plus@30";
                args = [
                  "with-xwidgets"
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
            };

          };

          home-manager.backupFileExtension = "backup";

          users.users.${username} = {
            name = username;
            home = "/Users/${username}";

            shell = pkgs.zsh;
            ignoreShellProgramCheck = true;

            ## NOTE: are these needed anymore?
            # uid = 501;
          };

          nix.package = pkgs.nix;

          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 6;
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
            home-manager.useUserPackages = false; # TEST:
            home-manager.users.${username} = {
              imports = [ ./home.nix ];
            };
            home-manager.extraSpecialArgs = {
              inherit username;
            };

          }
        ];
      };

      darwinPackages = self.darwinConfigurations.${hostname}.pkgs;
    };
}
