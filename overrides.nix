{
  buildPythonPackage,
  fetchPypi,
  inputs,
  lib,
  qt6,
  stdenvNoCC,
  writeShellScriptBin,

  # build-system
  poetry-core,
  setuptools,
  setuptools-scm,

  # dependencies
  aiohttp,
  dulwich,
  evdev,
  hatchling,
  hidapi,
  hjson,
  importlib-metadata,
  inflect,
  jsonpickle,
  kaitaistruct,
  lxml,
  numpy,
  odfpy,
  plover,
  prompt-toolkit,
  pyfiglet,
  pygame,
  pypandoc,
  pyparsing,
  pysdl2,
  pystray,
  python-rtmidi,
  pyudev,
  tomli,
  ruamel-yaml,
  xkbcommon,
  websocket-client,

  # test
  pytest,
  pytestCheckHook,
}:
let
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
in
final: prev: {
  # alleycat-link

  plover2cat = buildPythonPackage {
    pname = "plover2cat";
    version = "master";
    src = inputs.plover2cat;
    pyproject = true;
    build-system = [ setuptools ];
    buildInputs = [ plover ];
    dependencies = [
      dulwich
      odfpy
      pyparsing
      spylls
      obsws-python
    ];
    postPatch = ''
      substituteInPlace "setup.cfg" --replace-fail "PySide6-Essentials" "PySide6"
      sed -i '/PySide6-Addons/d' 'setup.cfg'
      substituteInPlace "pyproject.toml" --replace-fail "plover[gui_qt]>=5.0.0.dev2" "plover"
    '';
  };

  plover-1password = prev.plover-1password.overridePythonAttrs (old: {
    # onepassword-sdk
    meta.broken = true;
  });

  plover-auto-identifier = prev.plover-auto-identifier.overridePythonAttrs (old: {
    dependencies = [ pytest ]; # This is very odd though!
  });

  # plover-auto-reconnect-machine

  plover-cards = prev.plover-cards.overridePythonAttrs (old: {
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  });

  plover-casecat = prev.plover-casecat.overridePythonAttrs (old: {
    nativeBuildInputs = [ setuptools-scm ];
    dependencies = [ kaitaistruct ];
  });

  plover-cat = prev.plover-cat.overridePythonAttrs (old: {
    meta.broken = true;
  });

  # plover-clippy
  # plover-clippy-2
  # plover-clr-trans-state

  plover-combo = prev.plover-combo.overridePythonAttrs (old: {
    postPatch = ''
      substituteInPlace "pyproject.toml" --replace-fail "plover[gui_qt]>=5.0.0.dev2" "plover"
    '';
  });

  # plover-comment

  plover-console-ui = prev.plover-console-ui.overridePythonAttrs (old: {
    dependencies = [ prompt-toolkit ];
  });

  plover-controller = prev.plover-controller.overridePythonAttrs (old: {
    dependencies = [ pysdl2 ];
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  });

  # plover-current-time
  # plover-cycle-translations

  plover-debugging-console = prev.plover-debugging-console.overridePythonAttrs (old: {
    # background_zmq_ipython
    meta.broken = true;
  });

  # plover-delay

  plover-dict-commands = prev.plover-dict-commands.overridePythonAttrs (old: {
    nativeBuildInputs = [ setuptools-scm ];
  });

  # plover-dictionary-builder

  plover-dictionary-builder = prev.plover-dictionary-builder.overridePythonAttrs (old: {
    # `plover_build_utils.setup` does not export `Test`. Also the got the following error:
    # AttributeError: module 'plover_build_utils.pyqt' has no attribute 'fix_icons'
    meta.broken = true;
  });

  # plover-dictionary-patch

  plover-digitalcat-dictionary = prev.plover-digitalcat-dictionary.overridePythonAttrs (old: {
    nativeBuildInputs = [ setuptools-scm ];
    # It tries to access to `plover_casecat_dictionary.EclipseDictionary`, but there's no such item
    meta.broken = true;
  });

  plover-eclipse-dictionary = prev.plover-eclipse-dictionary.overridePythonAttrs (old: {
    nativeBuildInputs = [ setuptools-scm ];
    # It tries to access to `plover_casecat_dictionary:EclipseDictionary`, but there's no such item
    meta.broken = true;
  });

  plover-engine-server-2 = prev.plover-engine-server-2.overridePythonAttrs (old: {
    dependencies = [
      aiohttp
      jsonpickle
    ];
  });

  plover-emoji =
    let
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
    prev.plover-emoji.overridePythonAttrs (old: {
      dependencies = [
        simplefuzzyset
      ];
    });

  plover-excel-dictionary = prev.plover-excel-dictionary.overridePythonAttrs (old: {
    # pyexcel-xlsx
    meta.broken = true;
  });

  plover-fancytext = prev.plover-fancytext.overridePythonAttrs (old: {
    dependencies = [ pyfiglet ];
  });

  plover-french-extended-stenotype = prev.plover-french-extended-stenotype.overridePythonAttrs (old: {
    dependencies = [ final.plover-python-dictionary ];
  });

  # plover-german-syllatype
  # plover-grandjean

  plover-hjson-dictionary = prev.plover-hjson-dictionary.overridePythonAttrs (old: {
    dependencies = [ hjson ];
    # ImportError: cannot import name 'STROKE_DELIMITER' from 'plover.steno'
    meta.broken = true;
  });

  # plover-italian-stentura
  # plover-json-lazy

  plover-lapwing-aio = prev.plover-lapwing-aio.overridePythonAttrs (old: {
    dependencies = [
      final.plover-stitching
      final.plover-python-dictionary
      final.plover-modal-dictionary
      final.plover-last-translation
      final.plover-dict-commands
    ];
    # NOTE: Remove it on failure:
    postPatch = ''
      substituteInPlace "setup.cfg" --replace-fail "setuptools<77" "setuptools"
    '';
  });

  # plover-last-translation

  plover-listening-lookup = prev.plover-listening-lookup.overridePythonAttrs (old: {
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  });

  # plover-local-env-var
  # plover-maajik

  plover-markdown-dictionary = prev.plover-markdown-dictionary.overridePythonAttrs (old: {
    # importlib_metadata is not used. Update the upstream repository.
    postPatch = ''
      substituteInPlace setup.cfg --replace-fail 'importlib_metadata' ""
    '';
  });

  plover-melani = prev.plover-melani.overridePythonAttrs (old: {
    dependencies = [ final.plover-python-dictionary ];
  });

  # plover-merge-words

  # plover-michela
  plover-michela = prev.plover-michela.overridePythonAttrs (old: {
    dependencies = [ final.plover-midi ];
    meta.broken = final.plover-midi.meta.broken;
  });

  plover-midi = prev.plover-midi.overridePythonAttrs (old: {
    dependencies = [ python-rtmidi ];
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  });

  plover-midi4text = prev.plover-midi4text.overridePythonAttrs (old: {
    dependencies = [ final.plover-midi ];
    meta.broken = final.plover-midi.meta.broken;
  });

  # plover-minimal-english-stenotype
  # plover-mod-z
  # plover-modal-dictionary

  plover-next-stroke = prev.plover-next-stroke.overridePythonAttrs (old: {
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  });

  # plover-ninja
  # plover-number-format

  plover-oft-eva = prev.plover-oft-eva.overridePythonAttrs (old: {
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  });

  # plover-open-url
  # plover-palantype
  # plover-palantype-DE

  plover-phenrsteno = prev.plover-phenrsteno.overridePythonAttrs (old: {
    dependencies = [ pypandoc ];
  });

  # plover-phoenix-stenotype
  # plover-platform-specific-translation

  plover-plugins-manager = prev.plover-plugins-manager.overridePythonAttrs (old: {
    # AttributeError: module 'plover_build_utils.pyqt' has no attribute 'fix_icons'
    meta.broken = true;
  });

  # plover-portuguese
  # plover-python-dictionary
  # plover-q-and-a

  plover-regenpfeifer = prev.plover-regenpfeifer.overridePythonAttrs (old: {
    dependencies = [
      pygame
      numpy
    ];
  });

  # plover-retro-case
  # plover-retro-everything
  # plover-retro-quotes
  # plover-retro-stringop
  # plover-retro-surround
  # plover-retro-text-transform

  plover-retro-untranslator = prev.plover-retro-untranslator.overridePythonAttrs (old: {
    # - pyqt5 not installed
    meta.broken = true;
  });

  # plover-roll-the-dice
  # plover-rpn-calculator

  plover-run-applescript = prev.plover-run-applescript.overridePythonAttrs (old: {
    # mac-pyxa
    meta.broken = true;
  });

  # plover-run-shell
  # plover-russian-trillo

  plover-search-translation = prev.plover-search-translation.overridePythonAttrs (old: {
    # AttributeError: module 'plover_build_utils.pyqt' has no attribute 'fix_icons'
    meta.broken = true;
  });

  plover-sound = prev.plover-sound.overridePythonAttrs (old: {
    dependencies = [
      pygame
      numpy
    ];
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  });

  plover-spanish-mqd = prev.plover-spanish-mqd.overridePythonAttrs (old: {
    dependencies = [ final.plover-python-dictionary ];
    postPatch = ''
      substituteInPlace setup.cfg --replace-fail 'plover~=4.0.0.dev10' plover
    '';
  });

  plover-spanish-system-eo-variant = prev.plover-spanish-system-eo-variant.overridePythonAttrs (old: {
    postPatch = ''
      substituteInPlace setup.py --replace-fail 'plover>=4.0.0.dev0' plover
    '';
  });

  # plover-start-words
  # plover-startup-py
  # plover-steno-engine-hooks-logger

  plover-stenobee = prev.plover-stenobee.overridePythonAttrs (old: {
    dependencies = [
      inflect
      final.plover-python-dictionary
    ];
  });

  plover-stenograph = prev.plover-stenograph.overridePythonAttrs (old: {
    # pyusb-libusb1-backend
    meta.broken = true;
  });

  plover-stenohid-test = prev.plover-stenohid-test.overridePythonAttrs (old: {
    # plover-hid with automatic reconnect is in plover now
    meta.broken = true;
  });

  # plover-stenotype-extended
  # plover-stitching

  plover-svg-layout-display = prev.plover-svg-layout-display.overridePythonAttrs (old: {
    dependencies = [ lxml ];
    pythonImportsCheck = [
      "plover_svg_layout_display"
      # FIXME: This should pass
      # "plover_svg_layout_display.layout_ui"
    ];
    meta.broken = true;
  });

  # plover_system_switcher
  # plover-tapey-tape
  # plover-textarea

  plover-trayicon = prev.plover-trayicon.overridePythonAttrs (old: {
    dependencies = [
      pystray
    ];
    meta.broken = stdenvNoCC.isDarwin;
  });

  plover-treal = prev.plover-treal.overridePythonAttrs (old: {
    # hiadpi
    meta.broken = true;
  });

  plover-uinput = prev.plover-uinput.overridePythonAttrs (old: {
    dependencies = [
      evdev
      xkbcommon
    ];

    # NOTE: Don't know if it works breaking the constraint
    postPatch = ''
      substituteInPlace setup.cfg --replace-fail 'xkbcommon<1.1' xkbcommon
    '';

    meta.broken = stdenvNoCC.isDarwin;
  });

  # plover-unused-xtest-output

  plover-vcs-plugin = prev.plover-vcs-plugin.overridePythonAttrs (old: {
    # ImportError: cannot import name 'Test' from 'plover_build_utils.setup'
    meta.broken = true;
  });

  # plover-vipe
  # plover-vlc-commands

  plover-websocket-server = prev.plover-websocket-server.overridePythonAttrs (old: {
    # aiohttp
    meta.broken = true;
  });

  plover-windows-brightness = prev.plover-windows-brightness.overridePythonAttrs (old: {
    # pymi
    meta.broken = true;
  });

  plover-word-tray = prev.plover-word-tray.overridePythonAttrs (old: {
    # ModuleNotFoundError: No module named 'PyQt5'
    meta.broken = true;
  });

  # plover-wtype-output

  plover-wpm-meter = prev.plover-wpm-meter.overridePythonAttrs (old: {
    # ImportError: cannot import name 'Test' from 'plover_build_utils.setup'
    meta.broken = true;
  });

  plover-xtest-input = prev.plover-xtest-input.overridePythonAttrs (old: {
    # `plover.oslayer.xkeyboardcontrol` doen't exist
    meta.broken = true;
  });

  plover-yaml-dictionary = prev.plover-yaml-dictionary.overridePythonAttrs (old: {
    dependencies = [ ruamel-yaml ];
  });

  plover-spectra-lexer = prev.plover-spectra-lexer.overridePythonAttrs (old: {
    # >        PyQt5>=5.14
    meta.broken = true;
  });
}
