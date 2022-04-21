# RenPyWeb - Ren'Py in your HTML5 web browser

This is the build environment for RenPyWeb.
## How to build

- See https://github.com/renpy/renpy-build/ - something like:

      git clone https://github.com/renpy/renpy-build/
      cd renpy-build/
      BASE=. bash ./nightly/git.sh
      # fix-up tasks ordering
      ./build.py --platform web

- Emscripten: you need to recompile everything on upgrade:

      rm -rf build/ install/ python-emscripten/2.7.18/build/
      make cythonclean
      emcc --clear-ports

- Recompile:

      make
      scripts/install_in_renpy.sh

- Package the game: from the Ren'Py interface,
  or using `scripts/distribute_game.sh` (basic testing only)


## How to run locally

      make testserver
      $BROWSER http://localhost:8000/


## How to make small-scale tests

Check the `pygame-example-*` targets. Symlink `pygame-example/main.py`
to the variant you wish to experiment with.

Also check the `native` target to try to run Ren'Py natively with some
Emscripten behavior.
