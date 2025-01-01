{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    devenv,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            {
              enterShell = ''export PATH="$HOME/.local/bin/:$PATH"'';
              languages.zig.enable = true;

              packages = with pkgs; [
                nixd
                alejandra

                gdb
                python3
                rr
                valgrind-light

                libGL
                wayland
                wayland-protocols

                libxkbcommon
                xorg.libX11
                xorg.libXrandr
                xorg.libXinerama
                xorg.libXcursor
                xorg.libXi
                xorg.libXext
              ];
            }
          ];
        };
      }
    );
}
