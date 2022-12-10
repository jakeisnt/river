{
  description = "An empty project that uses Zig.";

  inputs = {
    nixpkgs.url     = github:nixos/nixpkgs/release-22.05;
    flake-utils.url = github:numtide/flake-utils;
    zig.url         = github:mitchellh/zig-overlay;

    # Used for shell.nix
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
  };

  outputs = {
    self,
      nixpkgs,
      flake-utils,
      ...
  } @ inputs: let
    overlays = [
      # Other overlays
      (final: prev: {
        zigpkgs = inputs.zig.packages.${prev.system};
      })
    ];

    # Our supported systems are the same supported systems as the Zig binaries
    systems = builtins.attrNames inputs.zig.packages;

  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {inherit overlays system;};
      in rec {
        defaultPackage = pkgs.zigpkgs.master;
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            zigpkgs.master
          ];

          buildInputs = with pkgs; [
            wayland
            wayland-protocols
            wlroots
            pixman
            libxkbcommon
            libevdev
            pkg-config
          ];

          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath (with pkgs; [libxkbcommon libevdev pixman wlroots ])}:$LD_LIBRARY_PATH";
        };

        # For compatibility with older versions of the `nix` binary
        devShell = self.devShells.${system}.default;
      }
    );
}
