{
  description = "Framework Laptop Embedded Controller (EC) build environment";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    zephyr-nix.url = github:adisbladis/zephyr-nix;
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";

    ec.url = github:FrameworkComputer/EmbeddedController?ref=fwk-lotus-azalea-19573;
    ec.flake = false;

    u-boot.url = git+https://chromium.googlesource.com/chromiumos/third_party/u-boot?ref=upstream/next;
    u-boot.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    zephyr-nix,
    ec,
    u-boot,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      zephyr-sdk = zephyr-nix.packages.${system}.sdk-0_16.override {targets = ["arm-zephyr-eabi"];};

      python = pkgs.python312;
      pythonPkgs = pkgs.python312Packages;

      setProjectDynamicToLicense = ''
        ${pkgs.toml-cli}/bin/toml set pyproject.toml project.dynamic license | ${pkgs.moreutils}/bin/sponge pyproject.toml
        sed -e 's/dynamic = "license"/dynamic = ["license"]/' -i pyproject.toml
      '';
    in rec {
      formatter = pkgs.alejandra;

      packages.zmake = pythonPkgs.buildPythonPackage {
        name = "zmake";
        src = "${ec}/zephyr/zmake";
        pyproject = true;

        propagatedBuildInputs = with pkgs; [gcc dtc];

        postPatch = ''
          # TODO: binman not found.
            echo sed -e 's#"/bin:/usr/bin"#"/bin:/usr/bin:${pkgs.gcc}/bin:${pkgs.dtc}/bin","DYLD_LIBRARY_PATH":"${pkgs.dtc}/lib"#'  -i src/platform/ec/zephyr/zmake/zmake/jobserver.py
        '';
      };

      packages.binman = pythonPkgs.buildPythonPackage {
        name = "binman";
        src = "${u-boot}/tools/binman";
        pyproject = true;

        buildInputs = [pythonPkgs.setuptools];
        propagatedBuildInputs = [pythonPkgs.libfdt];

        postPatch = ''
          #sed -e 's/>=61.0/==68.2.2/' -i pyproject.toml
          sed -e 's/"pylibfdt"/"libfdt"/' -i pyproject.toml
          ${setProjectDynamicToLicense}
        '';
      };

      packages.dtoc = pythonPkgs.buildPythonPackage {
        name = "dtoc";
        src = "${u-boot}/tools/dtoc";
        pyproject = true;

        buildInputs = [
          pythonPkgs.setuptools
          pythonPkgs.libfdt
          packages.u_boot_pylib
        ];

        postPatch = ''
          sed -e 's/"pylibfdt"/"libfdt"/' -i pyproject.toml
          ${setProjectDynamicToLicense}
        '';
      };

      packages.u_boot_pylib = pythonPkgs.buildPythonPackage {
        name = "u_boot_pylib";
        src = pkgs.fetchPypi {
          pname = "u_boot_pylib";
          version = "0.0.6";
          sha256 = "mwbw339O51qNObu6Mn4FvLARI7Y6zSkdLxeCx49tNd0=";
        };
        pyproject = true;

        buildInputs = [pythonPkgs.setuptools];
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          zephyr-sdk
          python
          pythonPkgs.pyyaml
          pythonPkgs.pykwalify
          pythonPkgs.packaging
          pythonPkgs.pyelftools
          pythonPkgs.colorama
          pythonPkgs.setuptools
          pythonPkgs.libfdt # <- 311 version fails to build; can't build with pip.
          dtc
          cmake
          ninja
        ];
      };
    });
}
