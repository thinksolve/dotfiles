# home.nix
# home-manager switch 

{
  config,
  pkgs,
  username,
  ...
}:
let
  dotfiles_dir = "${config.home.homeDirectory}/.dotfiles";
  link_dotfiles = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles_dir}/${path}";
in
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  # home.homeDirectory = lib.mkForce "/Users/brightowl";
  home.stateVersion = "23.11";

  home.file = {
    ".hammerspoon".source = link_dotfiles "/hammerspoon";
    ".zshrc".source = link_dotfiles "/zsh/.zshrc";
    ".shell_functions.sh".source = link_dotfiles "/zsh/.shell_functions.sh";
    ".config/nvim".source = link_dotfiles "/nvim";
    ".config/iterm2".source = link_dotfiles "/iterm2";
    ".config/yazi".source = link_dotfiles "/yazi";
    ".config/nix".source = link_dotfiles "/nix";
    ".config/nix-darwin".source = link_dotfiles "/nix/darwin";
    # Add other dotfiles as needed
  };

  # packages that don't make sense system-wide
  # home.packages = [
  # ];
  #
  # home.sessionVariables = {
  # };

  # home.sessionPath = [
  #   "/run/current-system/sw/bin"
  #   "$HOME/.nix-profile/bin"
  # ];
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    # initExtra = ''
    #   # Add any additional configurations here
    #   export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
    #   if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    #     . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    #   fi
    # '';
  };
}
