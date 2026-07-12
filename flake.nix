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

      pkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ qtLldDarwinOverlay ];
        }
      );
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      treefmtEval = forEachSystem (
        pkgs: inputs.treefmt-nix.lib.evalModule pkgs { programs.nixfmt.enable = true; }
      );
    in
    {
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

      ploverPlugins = forEachSystem (
        pkgs:
        pkgs.python3Packages.callPackage ./plugins.nix {
          plover = pkgs.python3Packages.callPackage ./plover.nix { inherit inputs; };
          inherit inputs;
        }
      );

      packages = forEachSystem (pkgs: rec {
        default = plover;
        plover =
          let
            plover' = pkgs.python3Packages.callPackage ./plover.nix { inherit inputs; };
            withPlugins =
              f: # f is a function such as (ps: with ps; [ plugin names ])
              plover'.overridePythonAttrs (old: {
                dependencies = old.dependencies ++ (f self.ploverPlugins.${pkgs.stdenv.hostPlatform.system});
              });
          in
          plover' // { inherit withPlugins; };

        plover-full =
          let
            availablePloverPlugins = builtins.filter (x: x ? meta && !x.meta.broken) (
              builtins.attrValues self.ploverPlugins.${pkgs.stdenv.hostPlatform.system}
            );
            plover' = pkgs.python3Packages.callPackage ./plover.nix { inherit inputs; };
            plover'' = plover'.overridePythonAttrs (old: {
              dependencies = old.dependencies ++ availablePloverPlugins;
            });
            withPlugins =
              f: # f is a function such as (ps: with ps; [ plugin names ])
              plover'.overridePythonAttrs (old: {
                dependencies =
                  old.dependencies
                  ++ availablePloverPlugins
                  ++ (f self.ploverPlugins.${pkgs.stdenv.hostPlatform.system});
              });
          in
          plover'' // { inherit withPlugins; };

        update = pkgs.callPackage ./update.nix { inherit inputs; };
      });

      homeManagerModules = rec {
        plover = import ./hm-module.nix self;
      };
    };
}
