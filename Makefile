# RenPyWeb - build system entry point

# Copyright (C) 2019, 2020, 2021  Sylvain Beucler

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

CACHEROOT=$(CURDIR)/cache
BUILD=$(CURDIR)/build
INSTALLDIR=$(CURDIR)/install
PATCHESDIR=$(CURDIR)/patches
SCRIPTSDIR=$(CURDIR)/scripts

# development:
##CFLAGS=-s ASSERTIONS=2
##CXXFLAGS=-s ASSERTIONS=2
##LDFLAGS=-s ASSERTIONS=2 -g4
# Using -O3 because Python+extensions are using it by default
#CFLAGS=-O3 -s ASSERTIONS=1
#CXXFLAGS=-O3 -s ASSERTIONS=1
#LDFLAGS=-O3 -s ASSERTIONS=1 -g

# optimized
CFLAGS=-O3
CXXFLAGS=-O3
LDFLAGS=-O3 -s ASSERTIONS=0
#LDFLAGS=-O3 -s ASSERTIONS=1 -g  # quick debug


all: asyncify

export PY2VER=2.7.18
export PY3VER=3.8
export EMCC=emcc

PYGAME_SDL2_STATIC_OBJS=pygame_sdl2/emscripten-static/build-temp/gen-static/*.o pygame_sdl2/emscripten-static/build-temp/src/*.o

# Filter down the PYGAME_SDL2_STATIC_OBJS list to remove objects that Ren'Py doesn't use.
PYGAME_SDL2_RENPY_STATIC_OBJS=$(shell ls ${PYGAME_SDL2_STATIC_OBJS} | egrep -v 'pygame_sdl2.(font|mixer|mixer_music|render).o')

RENPY_OBJS=$(BUILD)/main-renpyweb-static.bc $(BUILD)/inittab.bc $(BUILD)/emscripten-static.bc $(BUILD)/importexport.bc \
	$(PYGAME_SDL2_RENPY_STATIC_OBJS) \
	renpy/module/emscripten-static/build-temp/*.o renpy/module/emscripten-static/build-temp/gen-static/*.o

# EMULATE_FUNCTION_POINTER_CASTS=1: for Python
# FORCE_FILESYSTEM=1: for file_packager.py resource bundles (.data)
# LZ4=1: support file_packager.py --lz4 (beware: creates read-only files, stored compressed in-memory)
# RETAIN_COMPILER_SETTINGS=1: 'compilerSettings' contains build info, for debugging (.js += 6kB)
# MINIFY_HTML=0	: so Ren'Py users can customize index.html
# ENVIRONMENT=web: just in case
# USE_SDL=2: use SDL2 "port" (upstream's Emscripten support is lagging)
# Cf. emscripten/src/settings.js
COMMON_LDFLAGS = \
	-L $(INSTALLDIR)/lib $(LDFLAGS) \
	-s EMULATE_FUNCTION_POINTER_CASTS=1 \
	-s FORCE_FILESYSTEM=1 -s LZ4=1 -s RETAIN_COMPILER_SETTINGS=1 \
	-s MINIFY_HTML=0 \
	-s ENVIRONMENT=web \
	-lpython2.7 \
	-s USE_SDL=2 \
	-lSDL2_image -ljpeg -lpng -lwebp -lz

### Stack save/restore points
# Test with both -O0 -g and -O3; e.g. SDL_WaitEvent/SDL_Delay may be listed as non-existing due to inlining
# Using wildcards for:
# - __Pyx_PyObject_CallNoArg homonymous functions that get a suffix at link time
# - Cython-generated function that may change (depends on functions order and Cython version)
# "_gen_send", "_gen_send_ex", "_gen_iternext", "_type_call", "_slot_tp_init"...:
#   possibly unnecessary, depends on where emscripten_sleep() is used in Python
# library_egl.js: don't put emscripten_sleep calls there (JS is not automatically instrumented)
# Last-resort stack trace inspection: manually console.trace() before the emscripten_sleep()s
# Without ASYNCIFY_WHITELIST perfs are now acceptable (unlike with Emterpreter), at the cost of increased .wasm size and compilation time
ASYNCIFY_LDFLAGS = \
	-s ASYNCIFY=1 -s ASYNCIFY_STACK_SIZE=65535 -s ASYNCIFY_IGNORE_INDIRECT=1  \
	-s ASYNCIFY_ONLY='["main", "pyapp_runmain", "SDL_WaitEvent", "SDL_WaitEventTimeout", "SDL_Delay", "SDL_RenderPresent", "GLES2_RenderPresent", "SDL_GL_SwapWindow", "Emscripten_GLES_SwapWindow", "byn$$fpcast-emu$$Emscripten_GLES_SwapWindow", "SDL_UpdateWindowSurface", "SDL_UpdateWindowSurfaceRects", "Emscripten_UpdateWindowFramebuffer", "PyRun_SimpleFileExFlags", "PyRun_FileExFlags", "PyEval_EvalCode", "PyEval_EvalCodeEx", "PyEval_EvalFrameEx", "PyCFunction_Call", "PyObject_Call", "fast_function", "byn$$fpcast-emu$$function_call", "function_call", "instancemethod_call", "byn$$fpcast-emu$$instancemethod_call", "byn$$fpcast-emu$$slot_tp_call", "slot_tp_call", "__pyx_pw_11pygame_sdl2_5event_7wait", "byn$$fpcast-emu$$__pyx_pw_11pygame_sdl2_5event_7wait", "__pyx_pw_11pygame_sdl2_7display_21flip", "byn$$fpcast-emu$$__pyx_pw_11pygame_sdl2_7display_21flip", "__pyx_pw_11pygame_sdl2_7display_6Window_13flip", "byn$$fpcast-emu$$__pyx_pw_11pygame_sdl2_7display_6Window_13flip", "__pyx_pf_5renpy_2gl_6gldraw_6GLDraw_*draw_screen", "__pyx_pw_5renpy_2gl_6gldraw_6GLDraw_*draw_screen", "byn$$fpcast-emu$$__pyx_pw_5renpy_2gl_6gldraw_6GLDraw_*draw_screen", "__pyx_pf_5renpy_3gl2_7gl2draw_7GL2Draw_*draw_screen", "__pyx_pw_5renpy_3gl2_7gl2draw_7GL2Draw_*draw_screen", "byn$$fpcast-emu$$__pyx_pw_5renpy_3gl2_7gl2draw_7GL2Draw_*draw_screen", "__Pyx_PyObject_CallNoArg*", "byn$$fpcast-emu$$__pyx_pw_10emscripten_*sleep", "__pyx_pf_10emscripten_*sleep", "__pyx_pw_10emscripten_*sleep", "gen_send", "gen_send_ex", "gen_iternext", "type_call", "slot_tp_init", "builtin_eval", "call_function", "OPFUNC_CALL_FUNCTION", "byn$$fpcast-emu$$OPFUNC_CALL_FUNCTION", "OPFUNC__call_function_var_kw", "byn$$fpcast-emu$$OPFUNC__call_function_var_kw", "OPFUNC_EXEC_STMT", "byn$$fpcast-emu$$OPFUNC_EXEC_STMT"]'

COMMON_PYGAME_EXAMPLE_LDFLAGS = \
	    -s USE_SDL_MIXER=2 \
	    -s USE_SDL_TTF=2

# See below for flags explanation
RENPY_LDFLAGS = \
	$(COMMON_LDFLAGS) \
	-lavformat -lavcodec -lavutil -lswresample -lswscale -lfreetype -lfribidi \
	-lzip \
	-lidbfs.js \
	-s EXPORTED_FUNCTIONS='["_main", "_Py_Initialize", "_PyRun_SimpleString", "_pyapp_runmain", "_emSavegamesImport", "_emSavegamesExport"]' \
	-s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
	-s FULL_ES2=1 \
	-s MAX_WEBGL_VERSION=2 \
	--emit-symbol-map \
	--shell-file renpy-shell.html --pre-js renpy-pre.js

# No SDL2_mixer nor SDL2_ttf, Ren'Py has its own audio/ttf support.
# Compile our own SDL2_image because Emscripten has no webp ports and a different libjpeg.

#	EMCC_FORCE_STDLIBS=gl -> attempt to force GL symbols
#	-s SDL2_IMAGE_FORMATS='["png","jpg","webp"]' -> not compiling properly + expect conflicts with direct uses of libjpg/libpng from pygame_sdl2

# OpenGL: deprecated client-side buffers, not a single use of
# glGenBuffers or glBindBuffer in all of Ren'Py (boo)...
# -s FULL_ES2=1

# Debug:
# compilation process: EMCC_DEBUG=2
# webgl tracing: -s GL_ASSERTIONS=1 -s GL_UNSAFE_OPTS=0 -s TRACE_WEBGL_CALLS=1 -s GL_DEBUG=1

# Dynamic compilation:
# -s MAIN_MODULE=1
# .so-s with -s SIDE_MODULE=1 -s EXPORT_ALL=1
#   if you want to set WASM=0 -> need to recompile all the Python .so-s
# 1.39.0 still has several issues with dynamic linking, including linking -fPIC in static projects

# Memory usage
# INITIAL_MEMORY=64MB is not enough to run 'the_question' and 'tutorial'
# (2019-10, with --no-heap-copy so without filesystem; minimal Python fits in ~6MB)
# INITIAL_MEMORY=96MB works for 'the_question' and 'tutorial'; beware: memory growth is x2
# INITIAL_MEMORY=128MB leaves a nice margin
# INITIAL_MEMORY=512MB usually won't run at all on mobile platforms and/or picky browsers
# ALLOW_MEMORY_GROWTH=1 so we can run any game; documented as efficient with WASM


dirs:
	mkdir -p $(BUILD)/t/

$(BUILD)/emscripten.c: $(BUILD)/python.built python-emscripten/emscripten.pyx
	cython -2 python-emscripten/emscripten.pyx -o $(BUILD)/emscripten.c
$(BUILD)/emscripten-static.bc: $(BUILD)/python.built $(BUILD)/emscripten.c
	$(EMCC) -c $(CFLAGS) $(BUILD)/emscripten.c -o $(BUILD)/emscripten-static.bc -I install/include/python2.7
$(BUILD)/emscripten-dynamic.bc: $(BUILD)/python.built $(BUILD)/emscripten.c
	$(EMCC) -c $(CFLAGS) -fPIC -s MAIN_MODULE=1 $(BUILD)/emscripten.c -o $(BUILD)/emscripten-dynamic.bc -I install/include/python2.7

$(BUILD)/main-pygame_sdl2-static.bc: main.c
	$(EMCC) -c $(CFLAGS) -DSTATIC=1 main.c -o $(BUILD)/main-pygame_sdl2-static.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/main-pygame_sdl2-dynamic.bc: main.c
	$(EMCC) -c $(CFLAGS) -fPIC -s MAIN_MODULE=1 main.c -o $(BUILD)/main-pygame_sdl2-dynamic.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/main-renpyweb-static.bc: main.c
	$(EMCC) -c $(CFLAGS) -DASYNC=1 -DSTATIC=1 -DRENPY=1 main.c -o $(BUILD)/main-renpyweb-static.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/importexport.bc: importexport.c $(BUILD)/libzip.built
	$(EMCC) -c $(CFLAGS) importexport.c -o $(BUILD)/importexport.bc -I install/include/

$(BUILD)/inittab.bc: inittab.c
	$(EMCC) -c $(CFLAGS) inittab.c -o $(BUILD)/inittab.bc -I install/include/ -I install/include/python2.7


common: check_emscripten dirs
common-pygame-example-static: common $(BUILD)/pygame_sdl2-static.built $(BUILD)/emscripten-static.bc package-pygame-example-static $(BUILD)/main-pygame_sdl2-static.bc
common-pygame-example-dynamic: common $(BUILD)/pygame_sdl2-dynamic.built $(BUILD)/emscripten-dynamic.bc package-pygame-example-dynamic $(BUILD)/main-pygame_sdl2-dynamic.bc

common-renpy: common $(BUILD)/main-renpyweb-static.bc $(BUILD)/inittab.bc $(BUILD)/emscripten-static.bc $(BUILD)/importexport.bc package-renpy

package-python-minimal:
	PREFIX=$(INSTALLDIR) \
	  OUTDIR=$(BUILD)/t \
	  python-emscripten/$(PY2VER)/package-pythonhome.sh
package-pygame-example-static: package-python-minimal
	$(CURDIR)/scripts/package-pyapp-pygame-example-static.sh
package-pygame-example-dynamic: package-python-minimal $(BUILD)/pygame_sdl2-dynamic.built
	$(CURDIR)/scripts/package-pyapp-pygame-example-dynamic.sh

package-renpy:
	# repr.py: for Developer mode > Variable viewer
	# encodings/raw_unicode_escape.py base64.py: for Ren'Py's tutorial
	# encodings/utf-32-be.py: .rpy from Ren'Py 6.x
	# webbrowser.py + shlex.py dep: click on URLs within Ren'Py
	# socket.py: websockets + urllib dependency
	# urllib.py: urllib.urlencode useful for encoding POST data
	# wave.py sunau.py chunk.py: for AudioData()
	# bisect.py: small module used in some games
	# logging/__init__.py atexit.py: basic logging included in Ren'Py
	PREFIX=$(INSTALLDIR) \
	  OUTDIR=$(BUILD)/t \
	  python-emscripten/$(PY2VER)/package-pythonhome.sh \
	  atexit.py \
	  base64.py \
	  bisect.py \
	  calendar.py \
	  cgi.py \
	  chunk.py \
	  cmd.py \
	  commands.py \
	  compileall.py \
	  cookielib.py \
	  Cookie.py \
	  cProfile.py \
	  decimal.py \
	  dummy_threading.py \
	  email/base64mime.py \
	  encodings/base64_codec.py \
	  encodings/cp437.py \
	  encodings/idna.py \
	  encodings/mbcs.py \
	  encodings/raw_unicode_escape.py \
	  encodings/string_escape.py \
	  encodings/unicode_escape.py \
	  encodings/utf_16_be.py \
	  encodings/utf_16_le.py \
	  encodings/utf_16.py \
	  encodings/utf_32_be.py \
	  encodings/utf_8.py \
	  getopt.py \
	  gzip.py \
	  hmac.py \
	  imghdr.py \
	  logging/__init__.py \
	  mimetools.py \
	  mimetypes.py \
	  ntpath.py \
	  nturl2path.py \
	  numbers.py \
	  optparse.py \
	  pstats.py \
	  py_compile.py \
	  Queue.py \
	  quopri.py \
	  repr.py \
	  rfc822.py \
	  shlex.py \
	  socket.py \
	  StringIO.py \
	  stringprep.py \
	  _strptime.py \
	  sunau.py \
	  urllib2.py \
	  urllib.py \
	  UserList.py \
	  UserString.py \
	  uuid.py \
	  uu.py \
	  wave.py \
	  webbrowser.py \
	  xml/parsers/expat.py \
	  xml/parsers/__init__.py
	  #SimpleHTTPServer.py \
	  #SocketServer.py \
	  #ftplib.py \
	  #httplib.py \
	  #_LWPCookieJar.py \
	  #_MozillaCookieJar.py \
	  #ssl.py \

	$(CURDIR)/scripts/package-pyapp-renpy.sh

package-renpy-python3:
	# repr.py: for Developer mode > Variable viewer
	# encodings/raw_unicode_escape.py base64.py: for Ren'Py's tutorial
	# encodings/utf-32-be.py: .rpy from Ren'Py 6.x
	# struct.py ... enum.py: common Ren'Py/Python deps
	# __future__.py .. fnmatch.py: pygame_sdl2
	# importlib/* json/*: static submodules work-around
	# webbrowser.py + shlex.py dep: click on URLs within Ren'Py
	# socket.py: websockets + urllib dependency
	# urllib.py: urllib.urlencode useful for encoding POST data
	# wave.py sunau.py chunk.py: for AudioData()
	PREFIX=$(INSTALLDIR) \
	  OUTDIR=$(BUILD)/t \
	  python-emscripten/$(PY3VER)/package-pythonhome.sh \
	  encodings/raw_unicode_escape.py base64.py \
	  encodings/utf_32_be.py \
          struct.py operator.py datetime.py random.py functools.py types.py \
          collections/__init__.py collections/abc.py \
          pickle.py copyreg.py _compat_pickle.py keyword.py heapq.py reprlib.py \
          re.py sre_compile.py sre_parse.py sre_constants.py enum.py \
	  __future__.py importlib/__init__.py warnings.py glob.py fnmatch.py \
	  importlib/abc.py importlib/machinery.py json/__init__.py \
	  json/decoder.py json/scanner.py json/encoder.py \
	  webbrowser.py shlex.py \
	  socket.py \
	  urllib.py \
	  wave.py sunau.py chunk.py
	$(CURDIR)/scripts/package-pyapp-renpy.sh


##
# pygame-example for faster configuration experiments
##
pygame-example-static: $(BUILD)/python.built common-pygame-example-static $(BUILD)/main-pygame_sdl2-static.bc $(BUILD)/emscripten-static.bc
	$(EMCC) $(BUILD)/main-pygame_sdl2-static.bc $(BUILD)/emscripten-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s INITIAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html
pygame-example-static-asyncify: $(BUILD)/python.built common-pygame-example-static $(BUILD)/main-pygame_sdl2-static.bc $(BUILD)/emscripten-static.bc
	$(EMCC) $(BUILD)/main-pygame_sdl2-static.bc $(BUILD)/emscripten-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    $(ASYNCIFY_LDFLAGS) \
	    -s INITIAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html
#pygame-example-dynamic-asyncify: TODO
pygame-example-dynamic: $(BUILD)/python.built common-pygame-example-dynamic package-pygame-example-dynamic $(BUILD)/emscripten-dynamic.bc
	$(EMCC) $(BUILD)/main-pygame_sdl2-dynamic.bc $(BUILD)/emscripten-dynamic.bc \
	    -s MAIN_MODULE=1 -s EXPORT_ALL=1 \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s INITIAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html
pygame-example-worker: $(BUILD)/python.built common-pygame-example-static $(BUILD)/emscripten-static.bc
# Not supported well enough, effort moved to PROXY_TO_PTHREAD
# Also not useful for Ren'Py as workers still need to return before they get events (cf. emterpreter)
# Requires https://github.com/kripken/emscripten/issues/5380 to fix incomplete SDL2 support in --proxy-to-worker
	mkdir build/package-worker/
	cp -a python-emscripten/$(PY2VER)/package/* build/package-worker/
	cp -a build/package-pyapp-pygame-example/* build/package-worker/
	$(EMCC) $(BUILD)/main-pygame_sdl2-static.bc $(BUILD)/emscripten-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s INITIAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
            --preload-file build/package-worker@/ \
	    -o $(BUILD)/t/index.html --proxy-to-worker

PYGAME_SDL2_PY3_STATIC_OBJS=pygame_sdl2/emscripten-py3-static/build-temp/gen3-static/*.o pygame_sdl2/emscripten-py3-static/build-temp/src/*.o
COMMON_LDFLAGS_PY3 = \
	-L $(INSTALLDIR)/lib $(LDFLAGS) \
	-s EMULATE_FUNCTION_POINTER_CASTS=1 \
	-s FORCE_FILESYSTEM=1 -s LZ4=1 -s RETAIN_COMPILER_SETTINGS=1 \
	-s MINIFY_HTML=0 \
	-s ENVIRONMENT=web \
	-lpython3.8 \
	-s USE_SDL=2 \
	-lSDL2_image -ljpeg -lpng -lwebp -lz
$(BUILD)/emscripten-py3.c: $(BUILD)/python3.built python-emscripten/emscripten.pyx
	cython -3 python-emscripten/emscripten.pyx -o $(BUILD)/emscripten-py3.c
$(BUILD)/emscripten-py3-static.bc: $(BUILD)/python3.built $(BUILD)/emscripten-py3.c
	$(EMCC) -c $(CFLAGS) $(BUILD)/emscripten.c -o $(BUILD)/emscripten-py3-static.bc -I install/include/python3.8
$(BUILD)/main-pygame_sdl2-py3-static.bc: main.c
	$(EMCC) -c $(CFLAGS) -DSTATIC=1 main.c -o $(BUILD)/main-pygame_sdl2-py3-static.bc -s USE_SDL=2 -I install/include/python3.8
package-python3-minimal:
	PREFIX=$(INSTALLDIR) \
	  OUTDIR=$(BUILD)/t \
	  python-emscripten/$(PY3VER)/package-pythonhome.sh \
	  encodings/raw_unicode_escape.py base64.py \
	  encodings/utf_32_be.py \
          struct.py operator.py datetime.py random.py functools.py types.py \
          collections/__init__.py collections/abc.py \
          pickle.py copyreg.py _compat_pickle.py keyword.py heapq.py reprlib.py \
          re.py sre_compile.py sre_parse.py sre_constants.py enum.py \
	  __future__.py importlib/__init__.py warnings.py glob.py fnmatch.py \
	  importlib/abc.py importlib/machinery.py json/__init__.py \
	  json/decoder.py json/scanner.py json/encoder.py \

common-pygame-example-py3-static: common $(BUILD)/pygame_sdl2-py3-static.built $(BUILD)/emscripten-py3-static.bc package-pygame-example-py3-static $(BUILD)/main-pygame_sdl2-py3-static.bc
package-pygame-example-py3-static: package-python3-minimal
	$(CURDIR)/scripts/package-pyapp-pygame-example-py3-static.sh
pygame-example-py3-static: $(BUILD)/python3.built common-pygame-example-py3-static $(BUILD)/main-pygame_sdl2-py3-static.bc $(BUILD)/emscripten-py3-static.bc
	$(EMCC) $(BUILD)/main-pygame_sdl2-py3-static.bc $(BUILD)/emscripten-py3-static.bc \
	    $(PYGAME_SDL2_PY3_STATIC_OBJS) \
	    $(COMMON_LDFLAGS_PY3) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s INITIAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html



##
# renpyweb-static-asyncify
##
asyncify: $(BUILD)/python.built $(BUILD)/renpy.built common-renpy versionmark
	$(EMCC) $(RENPY_OBJS) \
	    $(RENPY_LDFLAGS) \
	    $(ASYNCIFY_LDFLAGS) \
	    -s INITIAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    -o $(BUILD)/t/index.html


# Experimental - doesn't work
# -s ALLOW_MEMORY_GROWTH=0
#   ERROR:root:Memory growth is not yet supported with pthreads (1.38.19)
#   https://github.com/kripken/emscripten/issues/7382
# -s WASM=1
#   doesn't seem to work in FireFox 63 (i.e. SharedArrayBuffer not enough, also requires WASM threads)
#   better with 65.0a1 (nightly) and Chromium 70
#   https://github.com/kripken/emscripten/wiki/Pthreads-with-WebAssembly/
# Needed?
#   -s OFFSCREENCANVAS_SUPPORT=1 -s OFFSCREEN_FRAMEBUFFER=1
# WIP?
#   https://github.com/kripken/emscripten/pull/6201
#   https://github.com/kripken/emscripten/labels/HTML5%20API
#   https://github.com/kripken/emscripten/labels/multithreading
pthreads:
	mkdir -p $(BUILD)/t/pthreads/
	$(EMCC) \
	    -s USE_PTHREADS=1 -s PTHREAD_POOL_SIZE=2 -s PROXY_TO_PTHREAD=1 -s WASM=1 \
	    \
	    -L $(INSTALLDIR)/lib -O2 -s ASSERTIONS=1 \
	    $(BUILD)/main.bc $(BUILD)/emscripten-static.bc \
	    $(BUILD)/pygame_sdl2/emscripten-static/build-temp/gen/*.o $(BUILD)/pygame_sdl2/emscripten-static/build-temp/src/*.o \
	    $(BUILD)/renpy/module/emscripten-static/build-temp/*.o $(BUILD)/renpy/module/emscripten-static/build-temp/gen/*.o \
	    -s USE_SDL=2 -s USE_FREETYPE=1 \
	    -lSDL2_image -ljpeg -lpng -lwebp -lz \
	    -lpython2.7 \
	    -lavformat -lavcodec -lavutil -lswresample -lswscale -lfribidi \
	    -s EMULATE_FUNCTION_POINTER_CASTS=1 \
	    -s INITIAL_MEMORY=256MB -s ALLOW_MEMORY_GROWTH=0 \
	    -s FORCE_FILESYSTEM=1 \
	    -s EXPORTED_FUNCTIONS="['_main', '_malloc', '_Py_Initialize', '_PyRun_SimpleString', '_pyapp_runmain']" \
	    -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
	    -s FULL_ES2=1 \
	    --pre-js pre-pthreads.js \
	    --shell-file shell.html \
	    \
            -o $(BUILD)/t/pthreads/wasm.html



##
# Emscripten Mock for faster native testing
##
native:
	# scripts/native-static.sh
	mkdir -p $(BUILD)/native/pythonhome
	cp -a $(CURDIR)/python-emscripten/$(PY2VER)/package/* $(BUILD)/native/pythonhome/
	cp -a $(BUILD)/package-pyapp-renpy/lib $(BUILD)/native/pythonhome/
	cd $(BUILD)/renpy/ && PYTHONHOME=$(BUILD)/native/pythonhome RENPY_EMSCRIPTEN=1 PATH= ./main


check_emscripten:
	which $(EMCC)
	which emconfigure

versionmark:
	git describe --tags --dirty > $(BUILD)/t/renpyweb-version.txt

# Compress and factor files before uploading to a decent host
# (note: gzip broken for itch.io/newgrounds though)
preupload-clean:
	rm -f \
		$(BUILD)/t/index.js.orig.js \
		$(BUILD)/t/index.wasm.pre $(BUILD)/t/index.wast \
		$(BUILD)/t/index.bc
	sed -i -e 's/%%TITLE%%/RenPyWeb/' $(BUILD)/t/index.html

hosting-gzip: preupload-clean
	-bash -c "gzip -f $(BUILD)/t/index.{em,js,html}"
	-bash -c "gzip -f $(BUILD)/t/pythonhome{.data,-data.js}"
	-bash -c "gzip -f $(BUILD)/t/pyapp{.data,-data.js}"
	cp -a htaccess.txt $(BUILD)/t/.htaccess

gunzip:
	-bash -c "gunzip $(BUILD)/t/index.{em,js,html}.gz"
	-bash -c "gunzip $(BUILD)/t/pythonhome{.data,-data.js}.gz"
	-bash -c "gunzip $(BUILD)/t/pyapp{.data,-data.js}.gz"
	rm -f $(BUILD)/t/.htaccess

testserver:
	(cd build/t && python3 $(CURDIR)/testserver.py)

cythonclean: cythonobjclean
	rm -rf pygame_sdl2/*-static/ pygame_sdl2/*-dynamic/ renpy/module/*-static/ build/emscripten.c build/emscripten-*.c

cythonobjclean:
	rm -rf pygame_sdl2/emscripten*-static/ pygame_sdl2/emscripten*-dynamic/ renpy/module/emscripten*-static/ build/emscripten-*.bc
	rm -f build/pygame_sdl2-*.built build/renpy.built

$(BUILD)/python.built:
	$(MAKE) check_emscripten dirs  # not a dep so that we don't rebuild Python every time
	DESTDIR=$(INSTALLDIR) \
	  SETUPLOCAL=$(CURDIR)/Python-Modules-Setup.local \
	  $(CURDIR)/python-emscripten/$(PY2VER)/python.sh
	touch $(BUILD)/python.built

$(BUILD)/python3.built:
	$(MAKE) check_emscripten dirs  # not a dep so that we don't rebuild Python every time
	DESTDIR=$(INSTALLDIR) \
	  SETUPLOCAL=$(CURDIR)/Python3-Modules-Setup.local \
	  $(CURDIR)/python-emscripten/$(PY3VER)/python.sh
	touch $(BUILD)/python3.built

$(BUILD)/renpy.built: $(BUILD)/pygame_sdl2-static.built $(BUILD)/freetype.built $(BUILD)/fribidi.built $(BUILD)/ffmpeg.built
	$(SCRIPTSDIR)/renpy_modules-static.sh
	touch $(BUILD)/renpy.built

$(BUILD)/freetype.built: $(CACHEROOT)/freetype-2.10.1.tar.gz
	$(SCRIPTSDIR)/freetype.sh
	touch $(BUILD)/freetype.built

$(BUILD)/fribidi.built: $(CACHEROOT)/fribidi-1.0.7.tar.bz2
	$(SCRIPTSDIR)/fribidi.sh
	touch $(BUILD)/fribidi.built

# avformat avcodec avutil swresample swscale
$(BUILD)/ffmpeg.built: $(CACHEROOT)/ffmpeg-4.3.1.tar.bz2
	# Video currently unavailable, let's optimize size and (compilation) speed
	#$(SCRIPTSDIR)/ffmpeg.sh
	$(SCRIPTSDIR)/ffmpeg-audioonly.sh
	touch $(BUILD)/ffmpeg.built

$(BUILD)/pygame_sdl2-static.built: $(BUILD)/libjpeg-turbo.built $(BUILD)/libpng.built $(BUILD)/SDL2_image.built
	$(SCRIPTSDIR)/pygame_sdl2-static.sh
	touch $(BUILD)/pygame_sdl2-static.built

$(BUILD)/pygame_sdl2-py3-static.built: $(BUILD)/libjpeg-turbo.built $(BUILD)/libpng.built $(BUILD)/SDL2_image.built
	$(SCRIPTSDIR)/pygame_sdl2-py3-static.sh
	touch $(BUILD)/pygame_sdl2-py3-static.built

$(BUILD)/pygame_sdl2-dynamic.built: $(BUILD)/libjpeg-turbo.built $(BUILD)/libpng.built $(BUILD)/SDL2_image.built
	$(SCRIPTSDIR)/pygame_sdl2-dynamic.sh
	touch $(BUILD)/pygame_sdl2-dynamic.built

$(BUILD)/libjpeg-turbo.built: $(CACHEROOT)/libjpeg-turbo-1.5.3.tar.gz
	$(SCRIPTSDIR)/libjpeg-turbo.sh
	touch $(BUILD)/libjpeg-turbo.built

$(BUILD)/libpng.built: $(CACHEROOT)/libpng-1.6.37.tar.gz $(BUILD)/zlib.built
	$(SCRIPTSDIR)/libpng.sh
	touch $(BUILD)/libpng.built

$(BUILD)/zlib.built: $(CACHEROOT)/zlib-1.2.11.tar.gz
	$(SCRIPTSDIR)/zlib.sh
	touch $(BUILD)/zlib.built

$(BUILD)/libwebp.built: $(CACHEROOT)/libwebp-1.1.0.tar.gz
	$(SCRIPTSDIR)/libwebp.sh
	touch $(BUILD)/libwebp.built

$(BUILD)/libzip.built: $(CACHEROOT)/libzip-1.7.3.tar.gz
	$(SCRIPTSDIR)/libzip.sh
	touch $(BUILD)/libzip.built

# Note: do not mix USE_SDL_IMAGE=2 (2.0.0 and -lSDL2_image (2.6.2)
# I got weird errors with dynamic linking, possibly they are not 100% compatible
$(BUILD)/SDL2_image.built: $(CACHEROOT)/SDL2_image-2.6.2.tar.gz $(BUILD)/libpng.built $(BUILD)/libjpeg-turbo.built $(BUILD)/libwebp.built
	$(SCRIPTSDIR)/SDL2_image.sh
	touch $(BUILD)/SDL2_image.built

$(CACHEROOT)/libjpeg-turbo-1.5.3.tar.gz:
	wget https://sourceforge.net/projects/libjpeg-turbo/files/1.5.3/libjpeg-turbo-1.5.3.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/libpng-1.6.37.tar.gz:
	wget http://prdownloads.sourceforge.net/libpng/libpng-1.6.37.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/freetype-2.10.1.tar.gz:
	wget https://download.savannah.gnu.org/releases/freetype/freetype-2.10.1.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/fribidi-1.0.7.tar.bz2:
	wget https://github.com/fribidi/fribidi/releases/download/v1.0.7/fribidi-1.0.7.tar.bz2 -P $(CACHEROOT)

$(CACHEROOT)/ffmpeg-4.3.1.tar.bz2:
	wget https://ffmpeg.org/releases/ffmpeg-4.3.1.tar.bz2 -P $(CACHEROOT)

#$(CACHEROOT)/SDL2-2.0.9.tar.gz:
#	wget https://libsdl.org/release/SDL2-2.0.9.tar.gz -P $(CACHEROOT)
# => USE_SDL=2 for now, it has lots of Emscripten fixes

$(CACHEROOT)/SDL2_image-2.6.2.tar.gz:
	wget https://libsdl.org/projects/SDL_image/release/SDL2_image-2.6.2.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/zlib-1.2.11.tar.gz:
	wget http://prdownloads.sourceforge.net/libpng/zlib-1.2.11.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/libwebp-1.1.0.tar.gz:
	wget https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.1.0.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/libzip-1.7.3.tar.gz:
	wget https://libzip.org/download/libzip-1.7.3.tar.gz -P $(CACHEROOT)
