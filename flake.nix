{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    plover = {
      url = "github:openstenoproject/plover";
      flake = false;
    };
    plover_plugins_registry = {
      url = "github:openstenoproject/plover_plugins_registry";
      flake = false;
    };
    rtf-tokenize = {
      url = "github:openstenoproject/rtf_tokenize";
      flake = false;
    };
    plover-stroke = {
      url = "github:openstenoproject/plover_stroke";
      flake = false;
    };
    plover2cat = {
      url = "github:greenwyrt/plover2CAT";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      systems = lib.systems.flakeExposed;

      # Inject Plover and its plugins into the Python package sets, so that they
      # are built against the same fixed point as the rest of the set
      # (e.g., `pyside6` and `qt6` with the Darwin fixes below).
      ploverOverlay = _final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyFinal: _pyPrev: {
            plover = pyFinal.callPackage ./plover.nix { inherit inputs; };
            ploverPlugins = pyFinal.callPackage ./plugins.nix { inherit inputs; };
          })
        ];
      };

      # [HACK]
      # Override cctools `ld` with LLVM's `lld` to avoid Qt 6.11 modules with naive Darwin plugins such as WebKit.
      # We patch `python.pkgs.qt6` rather than `pkgs.qt6`, because `overrideScope` on the latter drops its `.override`,
      # which `python-packages.nix` calls.
      qtLldDarwinOverlay =
        final: prev:
        lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (
              pyFinal: pyPrev:
              let
                withLld =
                  drv:
                  drv.overrideAttrs (old: {
                    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages.lld ];
                    env = (old.env or { }) // {
                      NIX_CFLAGS_LINK = "-fuse-ld=lld";
                    };
                  });
              in
              {
                pyside6 = withLld pyPrev.pyside6;
                qt6 = pyPrev.qt6.overrideScope (
                  _qtFinal: qtPrev:
                  lib.genAttrs [
                    "qtwebview"
                    "qtspeech"
                    "qtconnectivity"
                    "qtpositioning"
                    "qtlocation"
                  ] (name: withLld qtPrev.${name})
                );
              }
            )
          ];
        };

      overlays.default = lib.composeManyExtensions [
        ploverOverlay
        qtLldDarwinOverlay
      ];

      pkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ overlays.default ];
        }
      );
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      treefmtEval = forEachSystem (
        pkgs: inputs.treefmt-nix.lib.evalModule pkgs { programs.nixfmt.enable = true; }
      );
    in
    {
      inherit overlays;

      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt
            statix
            nixd
          ];
        };
      });

      formatter = forEachSystem (
        pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper
      );

      checks = forEachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
      });

      ploverPlugins = forEachSystem (pkgs: pkgs.python3Packages.ploverPlugins);

      packages = forEachSystem (pkgs: rec {
        default = plover;
        plover =
          let
            inherit (pkgs) python3Packages;
            withPlugins = pkgs.callPackage ./with-plugins.nix { };
          in
          (python3Packages.toPythonApplication python3Packages.plover) // { inherit withPlugins; };

        plover-full =
          let
            availablePlugins =
              plugins: builtins.filter (x: x ? meta && !x.meta.broken) (builtins.attrValues plugins);
            withPlugins =
              f: # f is a function such as (ps: with ps; [ plugin names ])
              plover.withPlugins (plugins: availablePlugins plugins ++ f plugins);
          in
          plover.withPlugins availablePlugins // { inherit withPlugins; };

        update = pkgs.callPackage ./update.nix { inherit inputs; };
      });

      homeManagerModules = rec {
        plover = import ./hm-module.nix self;
      };
    };
}
