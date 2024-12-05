{
  description = "Framework Laptop Embedded Controller (EC) build environment";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    zephyr-nix.url = github:adisbladis/zephyr-nix;
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    zephyr-nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      formatter = pkgs.alejandra;

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # pkgsCross.arm-embedded.buildPackages.gcc
          (zephyr-nix.packages.${system}.sdk-0_16.override {targets = ["arm-zephyr-eabi"];})
          # gcc-arm-embedded
          # gcc
          # gnumake
          # git-repo
          # swig # or swig3?
          python312
          python312Packages.libfdt  # <- 311 version fails to build
          dtc
          cmake
          file
          ninja
          # wget
          # uv
        ];
      };
    });
}
