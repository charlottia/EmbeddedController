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

      zephyr-sdk = zephyr-nix.packages.${system}.sdk-0_16.override {targets = ["arm-zephyr-eabi"];};

      python = pkgs.python312;
      pythonPkgs = pkgs.python312Packages;

      setProjectDynamicToLicense = ''
        ${pkgs.toml-cli}/bin/toml set pyproject.toml project.dynamic license | ${pkgs.moreutils}/bin/sponge pyproject.toml
        sed -e 's/dynamic = "license"/dynamic = ["license"]/' -i pyproject.toml
      '';

      pyelftools = pkgs.fetchgit {
        name = "pyelftools";
        url = "https://chromium.googlesource.com/chromiumos/third_party/pyelftools";
        rev = "refs/heads/chromeos-0.22";
        hash = "sha256-MArasbUre77vVGThaPxNotukIX+lGiNC4mhzZT52vl8=";
      };

      crosutils = pkgs.fetchgit {
        name = "crosutils";
        url = "https://chromium.googlesource.com/chromiumos/platform/crosutils";
        rev = "refs/heads/main";
        hash = "sha256-ahnXEetj99TLEocogZcSSUdj/r0QXiOw1OIVRrMt0cI=";
      };

      ec = pkgs.fetchFromGitHub {
        name = "ec";
        owner = "FrameworkComputer";
        repo = "EmbeddedController";
        rev = "fwk-lotus-azalea-19573";
        hash = "sha256-37iKyZdOy8K/a8fsvaTjiC9cTkcP0JbvsfB7t1XAIco=";
      };

      cmsis = pkgs.fetchgit {
        name = "cmsis";
        url = "https://chromium.googlesource.com/chromiumos/third_party/zephyr/cmsis";
        rev = "4aa3ff8e4f8a21e31cd9831b943acb7a7cd56ac8";
        hash = "sha256-IKmdIn/K1eHBVxA0sNvzr1i5LpkgJQMAMsks13lmDNw=";
      };

      hal_stm32 = pkgs.fetchgit {
        name = "hal_stm32";
        url = "https://chromium.googlesource.com/chromiumos/third_party/zephyr/hal_stm32";
        rev = "refs/heads/chromeos-main";
        hash = "sha256-r1aks0sgUrJeX8t2lO98sOtGjBMvHgt2St0am+qEz3E=";
      };

      zephyr = pkgs.fetchFromGitHub {
        name = "zephyr";
        owner = "FrameworkComputer";
        repo = "zephyr";
        rev = "lotus-zephyr";
        hash = "sha256-KgTh39Ba9jDByv7+9gDdZHCl2OOku3Y3yxq0Pt4GeBo=";
      };

      nanopb = pkgs.fetchgit {
        name = "nanopb";
        url = "https://chromium.googlesource.com/chromiumos/third_party/zephyr/nanopb";
        rev = "refs/heads/main";
        hash = "sha256-qt9ey7dbuqxIAhc4BKm0EqkMusOdsuQZNppmaN4ZVfA=";
      };

      u-boot = pkgs.fetchgit {
        name = "u-boot";
        url = "https://chromium.googlesource.com/chromiumos/third_party/u-boot";
        rev = "refs/heads/upstream/next";
        hash = "sha256-h5y0M1dupdO9CNG+OhUYi56UXsWAL5B0PTnhx+gU3FA=";
        fetchSubmodules = false;
      };

      depot_tools = pkgs.fetchgit {
        name = "depot_tools";
        url = "https://chromium.googlesource.com/chromium/tools/depot_tools";
        rev = "84edf22d0e5bf3f9ae60714ed9789fd62f86cf2a";
        hash = "sha256-3t03DdZ+dRen1z3PTyGt2rDPHIHTe+qS8ek/bH4kuKo=";
      };
    in rec {
      formatter = pkgs.alejandra;

      # TODO: generalise lotus v. azalea
      packages.default = packages.lotus;
      packages.lotus = pkgs.stdenv.mkDerivation {
        name = "lotus";
        
        srcs = [
          pyelftools
          crosutils
          ec
          cmsis
          hal_stm32
          zephyr
          nanopb
          u-boot
          depot_tools
        ];

        sourceRoot = ".";

        # TODO: see how much of the below we can remove and still get a build.
        postPatch = ''
          mkdir .repo

          mkdir -p chromite/third_party
          mv pyelftools chromite/third_party/pyelftools

          mkdir -p src
          mv crosutils src/scripts

          mkdir -p src/platform
          mv ec src/platform/ec

          mkdir -p src/third_party/zephyr
          mv cmsis src/third_party/zephyr/cmsis

          mkdir -p src/third_party/zephyr
          mv hal_stm32 src/third_party/zephyr/hal_stm32

          mkdir -p src/third_party/zephyr
          mv zephyr src/third_party/zephyr/main

          mkdir -p src/third_party/zephyr
          mv nanopb src/third_party/zephyr/nanopb

          mkdir -p src/third_party/u-boot
          mv u-boot src/third_party/u-boot/files

          mkdir -p src/chromium
          mv depot_tools src/chromium/depot_tools
        '';

        nativeBuildInputs = [
          zephyr-sdk
          pkgs.cmake
          pkgs.git
          pkgs.ninja
          pythonPkgs.pyyaml
          pythonPkgs.pykwalify
          pythonPkgs.packaging
          pythonPkgs.pyelftools
          pythonPkgs.colorama
          packages.binman
        ];

        dontUseCmakeConfigure = true;

        buildPhase = ''
          ${packages.zmake}/bin/zmake -j8 build lotus -DCMAKE_MAKE_PROGRAM="${pkgs.ninja}/bin/ninja" -DBUILD_VERSION=awawa
        '';
        installPhase = ''
          mkdir $out
          cp src/platform/ec/build/zephyr/lotus/output/* $out/
        '';
      };

      packages.zmake = pythonPkgs.buildPythonPackage {
        name = "zmake";
        src = ec;
        sourceRoot = "ec/zephyr/zmake";
        pyproject = true;
        build-system = [pythonPkgs.setuptools];

        # The DYLD_LIBRARY_PATH part here is only needed for Darwin, but it
        # doesn't harm Linux. TODO: don't do on Linux.
        postPatch = ''
          sed -e 's#"/bin:/usr/bin"#"/bin:/usr/bin:${pkgs.gcc}/bin:${pkgs.dtc}/bin","DYLD_LIBRARY_PATH":"${pkgs.dtc}/lib"#' -i zmake/jobserver.py
        '';
      };

      packages.binman = pythonPkgs.buildPythonPackage {
        name = "binman";
        src = "${u-boot}/tools/binman";
        pyproject = false;
        build-system = [pythonPkgs.setuptools];

        # zmake calls (sys.executable, path-to-binman, ...) on purpose, so we
        # can't wrap it. This makes it unsuitable for calling directly, however.
        dontWrapPythonPrograms = true;

        buildInputs = [
          pythonPkgs.pypaBuildHook
          pythonPkgs.pipInstallHook
        ];

        dependencies = [
          pythonPkgs.setuptools
          packages.u_boot_pylib
          pythonPkgs.libfdt
          packages.dtoc
        ];

        postPatch = ''
          sed -e 's/"pylibfdt"/"libfdt"/' -i pyproject.toml
          ${setProjectDynamicToLicense}
        '';

        # No wrapper => no need for args. I'd like to be able to still do this
        # to have a nicer binman derivation.
        # makeWrapperArgs = ["--set DYLD_LIBRARY_PATH ${pkgs.dtc}/lib"];
      };

      packages.dtoc = pythonPkgs.buildPythonPackage {
        name = "dtoc";
        src = "${u-boot}/tools/dtoc";
        pyproject = false;
        build-system = [pythonPkgs.setuptools];

        buildInputs = [
          pythonPkgs.pypaBuildHook
          pythonPkgs.pipInstallHook
        ];

        dependencies = [
          packages.u_boot_pylib
          pythonPkgs.libfdt
        ];

        postPatch = ''
          sed -e 's/"pylibfdt"/"libfdt"/' -i pyproject.toml
          ${setProjectDynamicToLicense}
        '';

        makeWrapperArgs = ["--set DYLD_LIBRARY_PATH ${pkgs.dtc}/lib"];
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

      # TODO: local builds in your area
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
          pythonPkgs.libfdt
          dtc
          cmake
          ninja
        ];
      };
    });
}
