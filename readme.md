# A flake for Plover with support for plugins

This is an experimental flake which packages Plover for Nix, along with support for plugins from the [Plover Plugins Registry](https://github.com/opensteno/plover_plugins_registry).

## Quick start

For a quick try, use `nix run`:

```sh
# start Plover with no plugin (default):
nix run github:openstenoproject/plover-flake

# start Plover with plugins:
nix run github:openstenoproject/plover-flake#plover-full
```

## Usage

Add this flake to your flake inputs:

```nix
{
  inputs = {
    plover-flake.url = "github:openstenoproject/plover-flake";
  };
  # ..
}
```

> [!NOTE]
> We upgraded Qt 5 to Qt 6 in April 2025 ([old version of README](https://github.com/openstenoproject/plover-flake/tree/6807afead2fb9e402dddb038d45b38e6226e94d1)). If you wish to keep using the old version of Plover, pin the input URL to `github:openstenoproject/plover-flake/6807afead2fb9e402dddb038d45b38e6226e94d1`.

Then a Plover derivation containing the plugins you want can be built with the following expression:

```nix
# ${system} is your platform (e.g., `x86_64-linux`)
inputs.plover-flake.packages.${system}.plover.withPlugins (ps: with ps; [
  plover-lapwing-aio
  plover-console-ui
])
```

`ps` is an attribute set containing every plugin from the registry.

Under the hood, `withPlugins` composes a Python environment (`python3.withPackages`) containing Plover and the selected plugins, so adding or removing plugins never rebuilds Plover itself. The underlying environment is exposed as `passthru.python-env`.

Alternatively, use the `plover-full` package, which bundles every non-broken plugin:

```nix
inputs.plover-flake.packages.${system}.plover-full
```

If you prefer composing your own `nixpkgs`, the flake also exports `overlays.default`, which injects `plover` and `ploverPlugins` into every Python package set (`python3Packages.plover`, `python3Packages.ploverPlugins`, ...):

```nix
import nixpkgs {
  inherit system;
  overlays = [ inputs.plover-flake.overlays.default ];
}
```

## home-manager module

If you use [home-manager](https://github.com/nix-community/home-manager), there is a module available. Here is an example of a configuration:

```nix
# any file imported by home-manager, e.g. home.nix

{ inputs, ... }: {
  imports = [
    inputs.plover-flake.homeManagerModules.plover
  ];

  programs.plover = {
    enable = true;
    package = inputs.plover-flake.packages.${pkgs.stdenv.hostPlatform.system}.plover.withPlugins (
      ps: with ps; [
        plover-lapwing-aio
      ]
    );

    # Or, use `plover-full` if you want Plover with all the plugins installed:
    # package = inputs.plover-flake.packages.${pkgs.stdenv.hostPlatform.system}.plover-full;

    # (optional) Generate `plover.cfg`:
    settings = {
      "Machine Configuration" = {
        machine_type = "Gemini PR";
        auto_start = true;
      };
      "Output Configuration".undo_levels = 100;
    };
  };
}
```

If you don't want Nix to manage the configuration of Plover, you can omit the `settings` value.

## NixOS configuration

To let Plover find serial ports, add your user to the `dialout` group:

```nix
users.users."YOUR USER".extraGroups = [ "dialout" ];
```

If you use Wayland, also add a udev rule for `uinput` and put your user in the `input` group so Plover can emit characters:

```nix
services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
'';

users.users."YOUR USER".extraGroups = [ "input" ];
```

## Troubleshooting

If a specific plugin fails to build it is most likely because of a missing dependency. In that case that dependency can be added to `overrides.nix`, any pull requests doing so are welcome.

## Q&A

### The fonts are too small

You may want to set `QT_SCALE_FACTOR` for DPI scaling:

```sh
QT_SCALE_FACTOR="1.5" nix run github:openstenoproject/plover-flake
```

You could set it via home-manager session variables, or you may want to wrap `plover` with a shell script. If you want builtin support, feel free to request!

