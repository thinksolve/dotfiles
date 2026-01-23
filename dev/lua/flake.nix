{
  description = "Lua/Teal development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          lua5_4
          lua54Packages.tl # Back to 0.24.8 from nixpkgs
        ];

        shellHook = ''
          echo "🌙 Lua/Teal development environment"
          echo "Teal version: $(tl --version)"
        '';
      };
    };
}
