# Point this to your patched Emscripten installation:
export PATH=$HOME/emscripten-git:$PATH
# If you have multiple emscripten installations:
# https://emscripten.org/docs/building_from_source/configuring_emscripten_settings.html#configuring-emscripten-settings
# https://emscripten.org/docs/tools_reference/emsdk.html#compiler-configuration-file
export EM_CONFIG=$HOME/.emscripten-renpyweb
export EM_PORTS=$HOME/.emscripten_ports-incoming-renpyweb
export EM_CACHE=$HOME/.emscripten_cache-incoming-renpyweb
