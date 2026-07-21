# Overrides for `buildPythonPackage` with `plugins.json` as defaults.
{
  buildPythonPackage,
  fetchFromGitHub,
  fetchPypi,
  inputs,
  stdenvNoCC,

  # build-system
  poetry-core,
  setuptools,
  setuptools-scm,

  # dependencies
  aiohttp,
  dulwich,
  evdev,
  hatchling,
  hjson,
  inflect,
  jsonpickle,
  kaitaistruct,
  lxml,
  numpy,
  odfpy,
  prompt-toolkit,
  pyfiglet,
  pygame-ce,
  pypandoc,
  pyparsing,
  pysdl2,
  pystardict,
  pystray,
  python-rtmidi,
  ruamel-yaml,
  tomli,
  websocket-client,
  xkbcommon,

  # test
  pytest,
}:
# The final plugin set:
plugins:
let
  # Package dependent libraries missing in nixpkgs:
  spylls = buildPythonPackage rec {
    pname = "spylls";
    version = "0.1.7";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-cEWJLcvTJNNoX2nFp2AGPnj7g5kTckzhgHfPCgyT8iA=";
    };

    # because `poetry` was removed from the toplevel python package, we must use `poetry-core`:
    build-system = [ poetry-core ];

    postPatch = ''
      substituteInPlace "pyproject.toml" --replace-fail 'poetry.masonry.api' 'poetry.core.masonry.api'
      substituteInPlace "pyproject.toml" --replace-fail 'poetry>=0.12' 'poetry-core'
    '';
  };
  obsws-python = buildPythonPackage rec {
    pname = "obsws_python";
    version = "1.6.1";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-n1l4M3xVfp+8pnO1rF3Ww7Vwyi6GCD3/QHLbrZOXp7w=";
    };

    build-system = [ setuptools ];

    buildInputs = [ hatchling ];
    dependencies = [
      tomli
      websocket-client
    ];
  };
  simplefuzzyset = buildPythonPackage rec {
    pname = "simplefuzzyset";
    version = "0.0.12";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-mhsww4tq+3bGYAvdZsHB3D2FBbCC6ePUZvYPQOi34fI=";
    };
    pyproject = true;
    build-system = [ setuptools ];
  };
in
{
  plover2cat = {
    version = "master";
    src = inputs.plover2cat;
    dependencies = [
      dulwich
      odfpy
      pyparsing
      pystardict
      spylls
      obsws-python
    ];
    postPatch = ''
      substituteInPlace "setup.cfg" --replace-fail "PySide6-Essentials" "PySide6"
      sed -i '/PySide6-Addons/d' 'setup.cfg'
      substituteInPlace "pyproject.toml" --replace-fail "plover[gui_qt]>=5.0.0.dev2" "plover"
    '';
  };

  # onepassword-sdk
  plover-1password.meta.broken = true;

  plover-auto-identifier.dependencies = [ pytest ]; # This is very odd though!

  # ModuleNotFoundError: No module named 'PyQt5'
  plover-cards.meta.broken = true;

  plover-casecat = {
    nativeBuildInputs = [ setuptools-scm ];
    dependencies = [ kaitaistruct ];
  };

  plover-cat.meta.broken = true;

  plover-combo.postPatch = ''
    substituteInPlace "pyproject.toml" --replace-fail "plover[gui_qt]>=5.0.0.dev2" "plover"
  '';

  plover-console-ui.dependencies = [ prompt-toolkit ];

  plover-controller = {
    dependencies = [ pysdl2 ];
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  };

  # background_zmq_ipython
  plover-debugging-console.meta.broken = true;

  plover-dict-commands.nativeBuildInputs = [ setuptools-scm ];

  # `plover_build_utils.setup` does not export `Test`. Also got the following error:
  # AttributeError: module 'plover_build_utils.pyqt' has no attribute 'fix_icons'
  plover-dictionary-builder.meta.broken = true;

  plover-digitalcat-dictionary = {
    nativeBuildInputs = [ setuptools-scm ];
    # It tries to access to `plover_casecat_dictionary.EclipseDictionary`, but there's no such item
    meta.broken = true;
  };

  plover-eclipse-dictionary = {
    nativeBuildInputs = [ setuptools-scm ];
    # It tries to access to `plover_casecat_dictionary:EclipseDictionary`, but there's no such item
    meta.broken = true;
  };

  plover-engine-server-2.dependencies = [
    aiohttp
    jsonpickle
  ];

  plover-emoji.dependencies = [
    # pkg_resources is injected via `plover.nix`
    simplefuzzyset
  ];

  # pyexcel-xlsx
  plover-excel-dictionary.meta.broken = true;

  plover-fancytext.dependencies = [ pyfiglet ];

  plover-french-extended-stenotype.dependencies = [ plugins.plover-python-dictionary ];

  plover-hjson-dictionary = {
    dependencies = [ hjson ];
    # ImportError: cannot import name 'STROKE_DELIMITER' from 'plover.steno'
    meta.broken = true;
  };

  plover-lapwing-aio = {
    dependencies = [
      plugins.plover-stitching
      plugins.plover-python-dictionary
      plugins.plover-modal-dictionary
      plugins.plover-last-translation
      plugins.plover-dict-commands
    ];
    # NOTE: Remove it on failure:
    postPatch = ''
      substituteInPlace "setup.cfg" --replace-fail "setuptools<77" "setuptools"
    '';
  };

  # ModuleNotFoundError: No module named 'PyQt5'
  plover-listening-lookup.meta.broken = true;

  # importlib_metadata is not used. Update the upstream repository.
  plover-markdown-dictionary.postPatch = ''
    substituteInPlace setup.cfg --replace-fail 'importlib_metadata' ""
  '';

  plover-melani.dependencies = [ plugins.plover-python-dictionary ];

  plover-michela = {
    dependencies = [ plugins.plover-midi ];
    meta.broken = plugins.plover-midi.meta.broken;
  };

  plover-midi = {
    dependencies = [ python-rtmidi ];
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  };

  plover-midi4text = {
    dependencies = [ plugins.plover-midi ];
    meta.broken = plugins.plover-midi.meta.broken;
  };

  # ModuleNotFoundError: No module named 'PyQt5'
  plover-next-stroke.meta.broken = true;

  # ModuleNotFoundError: No module named 'PyQt5'
  plover-oft-eva.meta.broken = true;

  plover-phenrsteno.dependencies = [ pypandoc ];

  plover-pinchord.dependencies = [ plugins.plover-python-dictionary ];

  # AttributeError: module 'plover_build_utils.pyqt' has no attribute 'fix_icons'
  plover-plugins-manager.meta.broken = true;

  # - pyqt5 not installed
  plover-retro-untranslator.meta.broken = true;

  # mac-pyxa
  plover-run-applescript.meta.broken = true;

  # AttributeError: module 'plover_build_utils.pyqt' has no attribute 'fix_icons'
  plover-search-translation.meta.broken = true;

  plover-sound = rec {
    version = "0.0.4";
    src = fetchPypi {
      pname = "plover-sound";
      inherit version;
      sha256 = "sha256-ZVn54enmC8ouxMTRHeNVudHSZUpUsDCMpUEQQunVjS4=";
    };
    dependencies = [
      pygame-ce
      numpy
    ];
    postPatch = ''
      substituteInPlace setup.cfg --replace-fail 'pygame' 'pygame-ce'
      substituteInPlace plover_sound/tool.py \
        --replace-fail "from PyQt5" "from PySide6" \
        --replace-fail "ICON = 'asset:plover_sound:icon.svg'" \
          "ICON = os.path.join(os.path.dirname(__file__), 'icon.svg')"
      # Prefer `asset:` URI and do not preserve absolute path to `/nix/store`
      substituteInPlace plover_sound/extension.py \
        --replace-fail "   default_sample_path = resource_filename(default_sample_path)" \
          "   pass" \
        --replace-fail "raise Exception(\"Couldn't find audio sample file\")" \
          "self.sample_path = default_sample_path"
    '';
  };

  plover-spanish-mqd = {
    dependencies = [ plugins.plover-python-dictionary ];
  };

  plover-spanish-system-eo-variant.postPatch = ''
    substituteInPlace setup.py --replace-fail 'plover>=4.0.0.dev0' plover
  '';

  plover-stenobee.dependencies = [
    inflect
    plugins.plover-python-dictionary
  ];

  # pyusb-libusb1-backend
  plover-stenograph.meta.broken = true;

  # plover-hid with automatic reconnect is in plover now
  plover-stenohid-test.meta.broken = true;

  plover-svg-layout-display = {
    # Because `layout_ui.py` is not in the PyPi distribution, we're fetching from GitHub:
    # https://github.com/opensteno/plover_svg_layout_display/issues/4
    src = fetchFromGitHub {
      owner = "opensteno";
      repo = "plover_svg_layout_display";
      rev = "50790c9b7f725dbb841da04a0fd76c5d1e875d38";
      hash = "sha256-/w22yzKwPnobDdCkuDFJ9atjfe3PuAiRCCWIw3I00/8=";
    };
    dependencies = [ lxml ];
    postPatch = ''
      substituteInPlace "pyproject.toml" --replace-fail "plover[gui_qt]>=5.0.0.dev3" "plover"
    '';
    pythonImportsCheck = [
      "plover_svg_layout_display"
      "plover_svg_layout_display.layout_ui" # not in PyPi version
    ];
  };

  plover-trayicon = {
    dependencies = [
      pystray
    ];
    meta.broken = stdenvNoCC.isDarwin;
  };

  # hiadpi
  plover-treal.meta.broken = true;

  plover-touch-tablets.meta.broken = true;

  plover-uinput = {
    dependencies = [
      evdev
      xkbcommon
    ];

    # NOTE: Don't know if it works breaking the constraint
    postPatch = ''
      substituteInPlace setup.cfg --replace-fail 'xkbcommon<1.1' xkbcommon
    '';

    meta.broken = stdenvNoCC.isDarwin;
  };

  # ImportError: cannot import name 'Test' from 'plover_build_utils.setup'
  plover-vcs-plugin.meta.broken = true;

  # aiohttp
  plover-websocket-server.meta.broken = true;

  # pymi
  plover-windows-brightness.meta.broken = true;

  # ModuleNotFoundError: No module named 'PyQt5'
  plover-word-tray.meta.broken = true;

  # ImportError: cannot import name 'Test' from 'plover_build_utils.setup'
  plover-wpm-meter.meta.broken = true;

  # `plover.oslayer.xkeyboardcontrol` doesn't exist
  plover-xtest-input.meta.broken = true;

  plover-yaml-dictionary.dependencies = [ ruamel-yaml ];

  # >        PyQt5>=5.14
  plover-spectra-lexer.meta.broken = true;
}
