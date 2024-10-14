{
  description = "Nix Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin ={
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    username = "brightowl";
    hostname = "bright";
    hostPlatform = "aarch64-darwin";

    # Helper function: 'pkg.meta.broken' is overridden to allow broken package
    unbreak = pkg: pkg.overrideAttrs (oldAttrs: { meta.broken = false; });
    # unbreak = pkg: 
    #   let newMeta = pkg.meta // { broken = false; };
    #   in pkg.overrideAttrs (oldAttrs: { meta = newMeta; });


    configuration = { pkgs, ... }: {

      # this required otherwise home.nix breaks build until i use lib.mkForce prefix on homeDirectory
      users.users.${username} = {
        name = username;
        home = "/Users/${username}";
      };

      environment.systemPackages =
        [ 
          # pkgs.chafa
          (unbreak pkgs.jp2a)
          # pkgs.vim
          pkgs.neovim #which nvim
          pkgs.iterm2
          pkgs.tree
          pkgs.ripgrep #which rg
          pkgs.git
          pkgs.curl
          pkgs.yazi
          pkgs.shfmt
          pkgs.shellcheck
          pkgs.fd
          pkgs.fzf
          pkgs.imagemagick #which magick (convert, identify)
          pkgs.ffmpeg
          pkgs.ffmpegthumbnailer
          pkgs.zig
          pkgs.ghostscript #which gs
          pkgs.pandoc
          pkgs.wget
          pkgs.poppler
          pkgs.poppler_utils
          pkgs.rename
          pkgs.htop
          pkgs.nmap
          pkgs.nghttp2
          # pkgs.tesseract
          # pkgs.unbound
          # pkgs.glib
      ];

      homebrew = {
        enable = true;
        casks = [
          "gimp"
          "firefox"
          "google-chrome"
          "brave-browser"
          "krita"
          "keka"
          "iina"
          "shottr"
          # "alfred"
          # "alfred@4"
          # "rectangle"
          # "rectangle-pro"
        ];
      };

      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;
      nix.settings.experimental-features = "nix-command flakes";
      programs.zsh.enable = true;  
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 5;
      nixpkgs.hostPlatform = hostPlatform;

      # NOTE: ... install script said to add this since a previous install had other nixbld users?
      nix.configureBuildUsers = true;

      system.defaults = {
          NSGlobalDomain.InitialKeyRepeat = 15;
          NSGlobalDomain.KeyRepeat = 2;
          dock.autohide = true;
          dock.mru-spaces = false;
          finder.AppleShowAllExtensions = true;
          finder.FXPreferredViewStyle = "clmv";
          screencapture.location = "~/screenshots";
          screensaver.askForPasswordDelay = 10;
          # loginwindow.LoginwindowText = "kalimba";
      };
    };
  in
  {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
      system = hostPlatform;
      modules = [
          configuration

          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit username; };
            # home-manager.users.${username} = { config, pkgs, ... }: import ./home.nix {
            #         inherit config pkgs username ;
            # }; 
          }
        ];
    };

    darwinPackages = self.darwinConfigurations.${hostname}.pkgs;
  };
}
