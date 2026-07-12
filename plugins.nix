{
  buildPythonPackage,
  callPackage,
  fetchPypi,
  lib,
  plover,
  setuptools,
  inputs,
}:
let
  pluginSpecs = builtins.fromJSON (builtins.readFile ./plugins.json);

  # Call `buildPythonPackage` for each package with default values in `plugins.json` and
  # custom values in `overrides.nix`. `fixes` is either an attrset or a override function.
  makePloverPlugin =
    spec: fixes:
    let
      defaults = {
        pname = spec.name;
        inherit (spec) version;
        src = fetchPypi {
          pname = lib.lists.head (builtins.split "-[0-9]" spec.filename);
          inherit (spec) version sha256;
        };
        pyproject = true;
        build-system = [ setuptools ];
        buildInputs = [ plover ];
      };
    in
    buildPythonPackage (defaults // (if lib.isFunction fixes then fixes defaults else fixes));

  makePlugins =
    self:
    let
      overrides = callPackage ./overrides.nix { inherit inputs; } self;
      registryPlugins = builtins.listToAttrs (
        map (spec: {
          inherit (spec) name;
          value = makePloverPlugin spec (overrides.${spec.name} or { });
        }) pluginSpecs
      );
      # Every override must correspond to a registry entry; this catches typos
      # and plugins removed from the registry.
      danglingOverrides = builtins.filter (name: !(registryPlugins ? ${name})) (
        builtins.attrNames overrides
      );
    in
    assert lib.assertMsg (
      danglingOverrides == [ ]
    ) "overrides.nix contains entries for plugins not in plugins.json: ${toString danglingOverrides}";
    registryPlugins;
in
lib.makeExtensible makePlugins
