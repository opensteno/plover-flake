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
    pyobjc = {
      url = "github:ronaldoussoren/pyobjc/v11.0";
      flake = false;
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
      pkgsFor = lib.genAttrs systems (system: import nixpkgs { inherit system; });
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    in
    {
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt-rfc-style
            statix
            nixd
          ];
        };
      });

      formatter = forEachSystem (pkgs: pkgs.nixfmt-tree);

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
            plover' = plover.withPlugins (
              ps: builtins.filter (x: x ? meta && !x.meta.broken) (builtins.attrValues ps)
            );
            withPlugins =
              f: # f is a function such as (ps: with ps; [ plugin names ])
              plover'.overridePythonAttrs (old: {
                dependencies = old.dependencies ++ (f self.ploverPlugins.${pkgs.stdenv.hostPlatform.system});
              });
          in
          plover' // { inherit withPlugins; };

        update = pkgs.callPackage ./update.nix { inherit inputs; };
      });

      homeManagerModules = rec {
        plover = import ./hm-module.nix self;
      };
    };
}
