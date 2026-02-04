{
  buildPythonPackage,
  inputs,
  lib,
  pkgs,
  stdenvNoCC,
  qt6,
  writeShellScriptBin,

  # build-system
  setuptools,

  # dependencies
  appdirs,
  babel,
  certifi,
  cmarkgfm,
  evdev,
  hidapi,
  psutil,
  pyside6,
  pyserial,
  requests-futures,
  packaging,
  pkginfo,
  pygments,
  readme-renderer,
  requests-cache,
  xlib,
  xkbcommon,
  wcwidth,

  # darwin
  appnope,
  pyobjc-core,
  pyobjc-framework-Cocoa,
  pyobjc-framework-Quartz,
}:
let
  # python-hidraw does not use hidapi by default
  # even though the documentation says that it should
  hidapi-hidraw = hidapi.overrideAttrs (old: {
    env = old.env // {
      HIDAPI_WITH_HIDRAW = true;
    };
  });
  plover-stroke = buildPythonPackage {
    pname = "plover_stroke";
    version = "master";
    src = inputs.plover-stroke;
    pyproject = true;
    build-system = [ setuptools ];
  };
  rtf-tokenize = buildPythonPackage {
    pname = "rtf_tokenize";
    version = "master";
    src = inputs.rtf-tokenize;
    pyproject = true;
    build-system = [ setuptools ];
  };
  # Matches missing pyside6-uic and pyside6-rcc implementations
  # https://github.com/NixOS/nixpkgs/issues/277849
  # https://github.com/NixOS/nixpkgs/blob/0ab0fd44102fd7259708584c6eafb78b1aeee0d3/pkgs/development/python-modules/openusd/default.nix#L44-L50
  # https://code.qt.io/cgit/pyside/pyside-setup.git/tree/sources/pyside-tools/pyside_tool.py?id=9b310d4c0654a244147766e382834b5e8bdeb762#n90
  pyside-tools-uic = writeShellScriptBin "pyside6-uic" ''
    exec ${qt6.qtbase}/libexec/uic -g python "$@"
  '';
  pyside-tools-rcc = writeShellScriptBin "pyside6-rcc" ''
    exec ${qt6.qtbase}/libexec/rcc -g python "$@"
  '';
in
buildPythonPackage {
  pname = "plover";
  version = "master";
  src = inputs.plover;
  pyproject = true;
  build-system = [ setuptools ];

  nativeBuildInputs = [
    qt6.qtbase
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtsvg # required for rendering icons
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    qt6.qtwayland
  ];

  # Other Plover plugins can depend on `plover_build_utils/setup.py`, so:
  propagatedNativeBuildInputs = [
    pyside-tools-uic
    pyside-tools-rcc
  ];

  dependencies = [
    babel
    hidapi-hidraw
    pyside6
    xlib
    pyserial
    appdirs
    wcwidth
    setuptools
    certifi
    packaging
    pkginfo
    pygments
    readme-renderer
    cmarkgfm
    requests-cache
    requests-futures
    plover-stroke
    psutil
    rtf-tokenize
    xkbcommon
  ]
  ++ lib.optionals stdenvNoCC.isLinux [
    evdev
  ]
  ++ lib.optionals stdenvNoCC.isDarwin [
    appnope
    pyobjc-core
    pyobjc-framework-Cocoa
    pyobjc-framework-Quartz
  ];

  pythonImportsCheck = [
    "plover"
    "plover.assets"
    "plover.command"
    "plover.dictionary"
    "plover.gui_none"
    "plover.gui_qt"
    "plover.gui_qt.resources"
    "plover.machine"
    "plover.machine.keyboard_capture"
    "plover.macro"
    "plover.messages"
    "plover.messages.es.LC_MESSAGES"
    "plover.messages.fr.LC_MESSAGES"
    "plover.messages.it.LC_MESSAGES"
    "plover.messages.nl.LC_MESSAGES"
    "plover.messages.zh_tw.LC_MESSAGES"
    "plover.meta"
    "plover.oslayer"
    "plover.oslayer.linux"
    "plover.oslayer.osx"
    "plover.oslayer.windows"
    "plover.output"
    "plover.plugins_manager"
    "plover.scripts"
    "plover.system"
    "plover_build_utils"
  ];

  # PySide6-Essentials it not on nixpkgs. See: https://github.com/NixOS/nixpkgs/issues/277849
  # In addition, plover requires xkbcommon<1.1, but nixpkgs has 1.5.1
  postPatch = ''
    substituteInPlace "pyproject.toml" --replace-fail "PySide6-Essentials" "PySide6"
    substituteInPlace "reqs/setup.txt" --replace-fail "PySide6-Essentials" "PySide6"
    substituteInPlace "reqs/dist_extra_gui_qt.txt" --replace-fail "PySide6-Essentials" "PySide6"
    substituteInPlace "reqs/constraints.txt" --replace-fail "PySide6-Essentials" "PySide6"
    substituteInPlace "reqs/dist.txt" --replace-fail "xkbcommon<1.1;" "xkbcommon<=1.5.1;"
  '';

  postInstall =
    lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
      mkdir -p $out/share/icons/hicolor/128x128/apps
      cp $src/plover/assets/plover.png $out/share/icons/hicolor/128x128/apps/plover.png
      mkdir -p $out/share/applications
      cp $src/linux/plover.desktop $out/share/applications/plover.desktop
      substituteInPlace "$out/share/applications/plover.desktop" \
        --replace-fail "Exec=plover" "Exec=$out/bin/plover"
    ''
    + lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
      APP_DIR="$out/Applications/Plover.app/Contents"
      mkdir -p $APP_DIR
      # TODO: Replace $year
      cp $src/osx/app_resources/Info.plist $APP_DIR/Info.plist
      mkdir -p $APP_DIR/Resources
      cp $src/osx/app_resources/plover.icns $APP_DIR/Resources/plover.icns
      mkdir -p $APP_DIR/MacOS
      makeWrapper "$out/bin/plover" "$APP_DIR/MacOS/Plover"
    '';

  # See: https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/qt.section.md
  dontWrapQtApps = true;
  preFixup = ''
    wrapQtApp "$out/bin/plover"
  '';
}
