# `plover.withPlugins` as a wrapper around `python3.withPackages`, following
# <https://github.com/NixOS/nixpkgs/pull/518828>. Plugins are injected by
# composing a Python environment, so adding plugins never rebuilds Plover
# itself. The wrapper exposes only Plover's executables to avoid installation
# collisions with other Python environments.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
}:

# selectPlugins is a function such as (ps: with ps; [ plugin names ])
selectPlugins:
let
  inherit (python3.pkgs) plover;
  python-env = python3.withPackages (ps: [ ps.plover ] ++ selectPlugins ps.ploverPlugins);
in
stdenvNoCC.mkDerivation {
  pname = "plover-with-plugins";
  inherit (plover) version;

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    for exe in ${lib.getBin plover}/bin/*; do
      makeWrapper "${lib.getBin python-env}/bin/$(basename "$exe")" "$out/bin/$(basename "$exe")"
    done
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    mkdir -p "$out/share"
    # `ln -s` would succeed even on a dangling target; fail loudly if the
    # install layout in plover.nix drifts.
    [ -d "${plover}/share/icons" ]
    ln -s "${plover}/share/icons" "$out/share/icons"
    mkdir -p "$out/share/applications"
    substitute "${plover}/share/applications/plover.desktop" "$out/share/applications/plover.desktop" \
      --replace-fail "Exec=${plover}/bin/plover" "Exec=$out/bin/plover"
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    APP_DIR="$out/Applications/Plover.app/Contents"
    mkdir -p "$APP_DIR"
    cp "${plover}/Applications/Plover.app/Contents/Info.plist" "$APP_DIR/Info.plist"
    cp -r "${plover}/Applications/Plover.app/Contents/Resources" "$APP_DIR/Resources"
    mkdir -p "$APP_DIR/MacOS"
    makeWrapper "$out/bin/plover" "$APP_DIR/MacOS/Plover"
  ''
  + ''
    runHook postInstall
  '';

  passthru = { inherit python-env; };

  meta.mainProgram = "plover";
}
