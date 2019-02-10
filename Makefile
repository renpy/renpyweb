# RenPyWeb - build system entry point

# Copyright (C) 2019  Sylvain Beucler

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
# Using -O3 because Python (and Python extensions) are using it by default
#CFLAGS=-s ASSERTIONS=2 -O3
#CXXFLAGS=-s ASSERTIONS=2 -O3
##LDFLAGS=-g3 -O3  # way too slow with asm.js - and buggy for wasm in renpyweb-pygame-example-emterpreter/
##LDFLAGS=-s ASSERTIONS=2 -g3 -O2  # heavy/slow
#LDFLAGS=-s ASSERTIONS=1 -g

# optimized (mostly useful for asm.js target):
CFLAGS=-O3
CXXFLAGS=-O3
LDFLAGS=-O2 -s ASSERTIONS=0
#LDFLAGS=-O2 -s ASSERTIONS=1 -g

# + EMT_STACK_MAX=2MB


all: wasm asmjs

PYGAME_SDL2_STATIC_OBJS=$(BUILD)/pygame_sdl2-static/emscripten-static/build-temp/gen/*.o $(BUILD)/pygame_sdl2-static/emscripten-static/build-temp/src/*.o

RENPY_OBJS=$(BUILD)/main-renpyweb-static.bc $(BUILD)/importexport.bc \
	$(PYGAME_SDL2_STATIC_OBJS) \
	$(BUILD)/renpy/module/emscripten-static/build-temp/*.o $(BUILD)/renpy/module/emscripten-static/build-temp/gen/*.o

# Ensure all builds use the same (locally patched) SDL2 instead of
# placing the default one in cache
# 'unexport' has the same global reach as 'export' T_T
EMCC_LOCAL_PORTS = sdl2emterpreter=$(BUILD)/SDL2
export EMCC_LOCAL_PORTS

COMMON_LDFLAGS = \
	-L $(INSTALLDIR)/lib $(LDFLAGS) \
	$(BUILD)/emscripten.bc \
	-s EMULATE_FUNCTION_POINTER_CASTS=1 \
	-s FORCE_FILESYSTEM=1 \
	-lpython2.7 \
	-s USE_SDL=2 \
	-lSDL2_image -ljpeg -lpng -lwebp -lz
# Using wildcard to target all __Pyx_PyObject_CallNoArg homonymous functions
# https://github.com/emscripten-core/emscripten/issues/7988
# https://github.com/emscripten-core/emscripten/pull/8056
EMTERPRETER_LDFLAGS = \
	-s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 \
	-s EMTERPRETIFY_WHITELIST='["_main", "_pyapp_runmain", "_SDL_WaitEvent", "_SDL_WaitEventTimeout", "_SDL_Delay", "_SDL_RenderPresent", "_GLES2_RenderPresent", "_SDL_GL_SwapWindow", "_Emscripten_GLES_SwapWindow", "_PyRun_SimpleFileExFlags", "_PyRun_FileExFlags", "_PyEval_EvalCode", "_PyEval_EvalCodeEx", "_PyEval_EvalFrameEx", "_PyCFunction_Call", "_PyObject_Call", "_fast_function", "_function_call", "_instancemethod_call", "_slot_tp_call", "___pyx_pw_11pygame_sdl2_5event_7wait", "___pyx_pw_11pygame_sdl2_7display_21flip", "___pyx_pw_11pygame_sdl2_7display_6Window_13flip", "___pyx_pf_5renpy_2gl_6gldraw_6GLDraw_30draw_screen", "___pyx_pw_5renpy_2gl_6gldraw_6GLDraw_31draw_screen", "___Pyx_PyObject_CallNoArg_*", "___pyx_pf_10emscripten_6sleep", "___pyx_pw_10emscripten_7sleep", "___pyx_pf_10emscripten_8sleep_with_yield", "___pyx_pw_10emscripten_9sleep_with_yield", "_gen_send", "_gen_send_ex", "_gen_iternext", "_type_call", "_slot_tp_init"]'
COMMON_PYGAME_EXAMPLE_LDFLAGS = \
	    -s USE_SDL_MIXER=2 \
	    -s USE_SDL_TTF=2 \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1
RENPY_LDFLAGS = \
	$(COMMON_LDFLAGS) \
	$(EMTERPRETER_LDFLAGS) \
	-s USE_FREETYPE=1 \
	-lavformat -lavcodec -lavutil -lswresample -lswscale -lfribidi \
	-lzip \
	-s EXPORTED_FUNCTIONS='["_main", "_Py_Initialize", "_PyRun_SimpleString", "_pyapp_runmain", "_emSavegamesImport", "_emSavegamesExport"]' \
	-s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
	-s FULL_ES2=1 \
	--shell-file renpy-shell.html --pre-js renpy-pre.js

# No SDL2_mixer nor SDL2_ttf, Ren'Py has its own audio/ttf support.
# Compile our own SDL2_image because Emscripten has no jpg/webp ports.

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

# Memory usage
# -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
# TOTAL_MEMORY=512MB causes issues on mobile platforms
# TOTAL_MEMORY=64MB is enough to run 'the_question' (on desktop) but not 'tutorial'
# TOTAL_MEMORY=128MB is a good compromise and fails early if e.g. a mobile platform doesn't have that much RAM
# ALLOW_MEMORY_GROWTH=1 so we can run any game; documented as efficient with WASM

# Emterpreter:
# -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -s EMTERPRETIFY_FILE=$(BUILD)/main.em
# -g4 -> -g3: https://github.com/kripken/emscripten/issues/6724
# emterpretify.py: EMT_STACK_MAX = 2*1024*1024
# Emterpreter notes:
# - for -s WASM=1, beware of https://github.com/kripken/emscripten/issues/6759
# -s --profiling-funcs : if needing function names in a stack trace, but SLOW
# -s EMTERPRETIFY_ADVISE=1: generate initial EMTERPRETIFY_WHITELIST
# - library_egl.js: don't put emscripten_sleep calls there (JS is non-emterpreted)

# => does not take _PyEval_EvalFrameEx/_PyEval_EvalCodeEx into
#    account? They still appear in assert's stack trace; it works though...
#    https://www.mail-archive.com/emscripten-discuss@googlegroups.com/msg07663.html
# => ___Pyx* function names may change when recompiling...
# => "_gen_send", "_gen_send_ex", "_gen_iternext", "_type_call", "_slot_tp_init"
#    added when experimenting with emscripten_sleep in python.py, otherwise not needed (?)


dirs:
	mkdir -p $(BUILD)/t/

$(BUILD)/emscripten.bc: python-emscripten/emscripten.pyx
	cython python-emscripten/emscripten.pyx -o $(BUILD)/emscripten.c
	emcc $(BUILD)/emscripten.c -o $(BUILD)/emscripten.bc -I install/include/python2.7

$(BUILD)/main-pygame_sdl2-static.bc: main.c
	emcc $(CFLAGS) -DSTATIC=1 main.c -o $(BUILD)/main-pygame_sdl2-static.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/main-pygame_sdl2-dynamic.bc: main.c
	emcc $(CFLAGS) main.c -o $(BUILD)/main-pygame_sdl2-dynamic.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/main-renpyweb-static.bc: main.c
	emcc $(CFLAGS) -DSTATIC=1 -DRENPY=1 main.c -o $(BUILD)/main-renpyweb-static.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/importexport.bc: importexport.c $(BUILD)/libzip.built
	emcc $(CFLAGS) importexport.c -o $(BUILD)/importexport.bc -I install/include/

common-pygame-example: dirs $(BUILD)/emscripten.bc $(BUILD)/SDL2.built
common-pygame-example-static: common-pygame-example package-pygame-example-static $(BUILD)/pygame_sdl2-static.built $(BUILD)/main-pygame_sdl2-static.bc
common-pygame-example-dynamic: common-pygame-example $(BUILD)/pygame_sdl2-dynamic.built $(BUILD)/main-pygame_sdl2-dynamic.bc

common-renpyweb: dirs $(BUILD)/emscripten.bc $(BUILD)/SDL2.built $(BUILD)/main-renpyweb-static.bc $(BUILD)/importexport.bc package-renpyweb

package-python-minimal:
	PREFIX=$(INSTALLDIR) \
	  OUTDIR=$(BUILD)/t \
	  python-emscripten/2.7.10/package-pythonhome.sh
package-pygame-example-static: package-python-minimal
	$(CURDIR)/scripts/package-pyapp-pygame-example-static.sh
package-pygame-example-dynamic-asmjs: package-python-minimal $(BUILD)/pygame_sdl2-dynamic.built
	$(CURDIR)/scripts/package-pyapp-pygame-example-dynamic.sh asmjs
package-pygame-example-dynamic-wasm: package-python-minimal $(BUILD)/pygame_sdl2-dynamic.built
	$(CURDIR)/scripts/package-pyapp-pygame-example-dynamic.sh wasm

package-renpyweb:
	# repr.py: for Developer mode > Variable viewer
	# encodings/raw_unicode_escape.py base64.py: for Ren'Py's tutorial
	# encodings/utf-32-be.py: .rpy from Ren'Py 6.x
	# encoding/ascii.py: for presplash?
	# webbrowser.py + shlex.py dep: click on URLs within Ren'Py
	PREFIX=$(INSTALLDIR) \
	  OUTDIR=$(BUILD)/t \
	  python-emscripten/2.7.10/package-pythonhome.sh \
	  repr.py \
	  encodings/raw_unicode_escape.py base64.py \
	  encodings/utf_32_be.py \
	  encodings/ascii.py \
	  webbrowser.py shlex.py
	$(CURDIR)/scripts/package-pyapp-renpy.sh


##
# pygame-example for faster configuration experiments
##
pygame-example-static-wasm: check_emscripten $(BUILD)/python.built common-pygame-example-static
	emcc $(BUILD)/main-pygame_sdl2-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html
	# work-around https://github.com/kripken/emscripten-fastcomp/pull/195
	sed -i -e 's/$$legalf32//g' $(BUILD)/t/index.js
	# currently broken (tested in 1.38.25, 1.38.27)
	# exception thrown: TypeError: cannot pass i64 to or from JS,ftCall_jiji@http://localhost:8000/index.js:13391:10
	# invoke_jiji@http://localhost:8000/index.js:13263:12
	# legalfunc$invoke_jiji@http://localhost:8000/index.js line 1557 > WebAssembly.instantiate:wasm-function[8183]:0x4fb0cf
	# _IMG_LoadPNG_RW@http://localhost:8000/index.js line 1557 > WebAssembly.instantiate:wasm-function[5051]:0x349f95
pygame-example-static-asmjs: check_emscripten $(BUILD)/python.built common-pygame-example-static
	emcc $(BUILD)/main-pygame_sdl2-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s TOTAL_MEMORY=256MB -s ALLOW_MEMORY_GROWTH=0 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html -s WASM=0
pygame-example-static-emterpreter-wasm: check_emscripten $(BUILD)/python.built common-pygame-example-static
	emcc $(BUILD)/main-pygame_sdl2-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    $(EMTERPRETER_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -s EMTERPRETIFY_FILE=$(BUILD)/t/index.em \
	    -o $(BUILD)/t/index.html
	# work-around https://github.com/kripken/emscripten-fastcomp/pull/195
	sed -i -e 's/$$legalf32//g' $(BUILD)/t/index.js
pygame-example-static-emterpreter-asmjs: check_emscripten $(BUILD)/python.built common-pygame-example-static
	emcc $(BUILD)/main-pygame_sdl2-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    $(EMTERPRETER_LDFLAGS) \
	    -s TOTAL_MEMORY=256MB -s ALLOW_MEMORY_GROWTH=0 \
	    --shell-file pygame-example-shell.html \
	    -s EMTERPRETIFY_FILE=$(BUILD)/t/index.em \
	    -o $(BUILD)/t/index.html -s WASM=0
#pygame-example-dynamic-emterpreter:
#	-> dynamic linking of Emterpreted functions not supported
pygame-example-dynamic-wasm: check_emscripten $(BUILD)/python.built common-pygame-example-dynamic package-pygame-example-dynamic-wasm
	emcc $(BUILD)/main-pygame_sdl2-dynamic.bc \
	    -s MAIN_MODULE=1 -s EXPORT_ALL=1 \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html
	# work-around https://github.com/kripken/emscripten-fastcomp/pull/195
	sed -i -e 's/$$legalf32//g' $(BUILD)/t/index.js
pygame-example-dynamic-asmjs: check_emscripten $(BUILD)/python.built common-pygame-example-dynamic package-pygame-example-dynamic-asmjs
	emcc $(BUILD)/main-pygame_sdl2-dynamic.bc \
	    -s MAIN_MODULE=1 -s EXPORT_ALL=1 \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s TOTAL_MEMORY=256MB -s ALLOW_MEMORY_GROWTH=0 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html -s WASM=0
pygame-example-worker: check_emscripten $(BUILD)/python.built common-pygame-example-static
# Not supported well enough, effort moved to PROXY_TO_PTHREAD
# Also not useful for Ren'Py as workers still need to return before they get events (cf. emterpreter)
# Requires https://github.com/kripken/emscripten/issues/5380 to fix incomplete SDL2 support in --proxy-to-worker
	mkdir build/package-worker/
	cp -a python-emscripten/2.7.10/package/* build/package-worker/
	cp -a build/package-pyapp-pygame-example/* build/package-worker/
	emcc $(BUILD)/main-pygame_sdl2-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
            --preload-file build/package-worker@/ \
	    -o $(BUILD)/t/index.html --proxy-to-worker
	# work-around https://github.com/kripken/emscripten-fastcomp/pull/195
	sed -i -e 's/$$legalf32//g' $(BUILD)/t/index.js


##
# renpyweb-static-emterpreter-wasm/asmjs
##
wasm: check_emscripten $(BUILD)/python.built $(BUILD)/renpy.built common-renpyweb
	emcc $(RENPY_OBJS) \
	    $(RENPY_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    -s EMTERPRETIFY_FILE=$(BUILD)/t/index.em \
	    -o $(BUILD)/t/index.html
	# work-around https://github.com/kripken/emscripten-fastcomp/pull/195
	sed -i -e 's/$$legalf32//g' $(BUILD)/t/index.js

asmjs: check_emscripten $(BUILD)/python.built $(BUILD)/renpy.built common-renpyweb
	# Using asmjs.html instead of asmjs/index.html because
	# e.g. itch.io picks a random index.html as entry point
	emcc $(RENPY_OBJS) \
	    $(RENPY_LDFLAGS) -s WASM=0 \
	    -s TOTAL_MEMORY=256MB -s ALLOW_MEMORY_GROWTH=0 \
            -s EMTERPRETIFY_FILE=$(BUILD)/t/asmjs.em \
	    -o $(BUILD)/t/asmjs.html



# pthreads - Experimental - doesn't work
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
pthreads-asmjs:
	env |grep PORT
	exit 1
	mkdir -p $(BUILD)/t/pthreads/
	emcc \
	    -s USE_PTHREADS=1 -s PTHREAD_POOL_SIZE=2 -s PROXY_TO_PTHREAD=1 -s WASM=0 \
	    \
	    -L $(INSTALLDIR)/lib -O0 -s ASSERTIONS=1 \
	    $(BUILD)/main.bc $(BUILD)/emscripten.bc \
	    $(BUILD)/pygame_sdl2/emscripten-static/build-temp/gen/*.o $(BUILD)/pygame_sdl2/emscripten-static/build-temp/src/*.o \
	    $(BUILD)/renpy/module/emscripten-static/build-temp/*.o $(BUILD)/renpy/module/emscripten-static/build-temp/gen/*.o \
	    -s USE_SDL=2 -s USE_FREETYPE=1 \
	    -lSDL2_image -ljpeg -lpng -lwebp -lz \
	    -lpython2.7 \
	    -lavformat -lavcodec -lavutil -lswresample -lswscale -lfribidi \
	    -s EMULATE_FUNCTION_POINTER_CASTS=1 \
	    -s TOTAL_MEMORY=256MB -s ALLOW_MEMORY_GROWTH=0 \
	    -s FORCE_FILESYSTEM=1 \
	    -s EXPORTED_FUNCTIONS="['_main', '_malloc', '_Py_Initialize', '_PyRun_SimpleString', '_pyapp_runmain']" \
	    -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
	    -s FULL_ES2=1 \
	    --pre-js pre.js \
	    --shell-file shell.html \
	    \
            -o $(BUILD)/t/pthreads/asmjs.html

# Experimental - doesn't work
pthreads-wasm:
	mkdir -p $(BUILD)/t/pthreads/
	emcc \
	    -s USE_PTHREADS=1 -s PTHREAD_POOL_SIZE=2 -s PROXY_TO_PTHREAD=1 -s WASM=1 \
	    \
	    -L $(INSTALLDIR)/lib -O2 -s ASSERTIONS=1 \
	    $(BUILD)/main.bc $(BUILD)/emscripten.bc \
	    $(BUILD)/pygame_sdl2/emscripten-static/build-temp/gen/*.o $(BUILD)/pygame_sdl2/emscripten-static/build-temp/src/*.o \
	    $(BUILD)/renpy/module/emscripten-static/build-temp/*.o $(BUILD)/renpy/module/emscripten-static/build-temp/gen/*.o \
	    -s USE_SDL=2 -s USE_FREETYPE=1 \
	    -lSDL2_image -ljpeg -lpng -lwebp -lz \
	    -lpython2.7 \
	    -lavformat -lavcodec -lavutil -lswresample -lswscale -lfribidi \
	    -s EMULATE_FUNCTION_POINTER_CASTS=1 \
	    -s TOTAL_MEMORY=256MB -s ALLOW_MEMORY_GROWTH=0 \
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
	cp -a $(CURDIR)/python-emscripten/2.7.10/package/* $(BUILD)/native/pythonhome/
	cp -a $(BUILD)/package-pyapp-renpy/lib $(BUILD)/native/pythonhome/
	cd $(BUILD)/renpy/ && PYTHONHOME=$(BUILD)/native/pythonhome RENPY_EMSCRIPTEN=1 PATH= ./main


check_emscripten:
	which emcc
	which emconfigure

# Compress and factor files before uploading to a decent host
# (note: gzip broken for itch.io though)
preupload-clean:
	rm -f \
		$(BUILD)/t/index.js.orig.js \
		$(BUILD)/t/index.wasm.pre $(BUILD)/t/index.wast \
		$(BUILD)/t/index.bc

hosting-nogzip-zip: preupload-clean
	rm -f $(CURDIR)/hosting.zip
	cd $(BUILD)/t && zip -r $(CURDIR)/hosting.zip .

hosting-gzip: preupload-clean
	-bash -c "gzip -f $(BUILD)/t/index.{em,js,html,wasm} $(BUILD)/t/pythonhome{.data,-data.js} $(BUILD)/t/pyapp{.data,-data.js}"
	-bash -c "gzip -f $(BUILD)/t/asmjs.{em,html,html.mem,js}"

gunzip:
	-gunzip $(BUILD)/t/*.gz


$(BUILD)/python.built:
	if [ ! -d python-emscripten ]; then \
	    fossil clone https://www.beuc.net/python-emscripten/python python-emscripten.fossil; \
	    mkdir python-emscripten; \
	    cd python-emscripten; \
	    fossil open ../python-emscripten.fossil; \
	fi
	DESTDIR=$(INSTALLDIR) \
	  SETUPLOCAL=$(CURDIR)/Python-Modules-Setup.local \
	  $(CURDIR)/python-emscripten/2.7.10/python.sh
	touch $(BUILD)/python.built

$(BUILD)/renpy.built: $(BUILD)/pygame_sdl2-static.built $(BUILD)/fribidi.built $(BUILD)/ffmpeg.built
	$(SCRIPTSDIR)/renpy_modules-static.sh
	touch $(BUILD)/renpy.built

$(BUILD)/fribidi.built: $(CACHEROOT)/fribidi-0.19.2.tar.gz
	$(SCRIPTSDIR)/fribidi.sh
	touch $(BUILD)/fribidi.built

# avformat avcodec avutil swresample swscale
$(BUILD)/ffmpeg.built: $(CACHEROOT)/ffmpeg-3.0.tar.bz2
	$(SCRIPTSDIR)/ffmpeg.sh
	touch $(BUILD)/ffmpeg.built

$(BUILD)/pygame_sdl2-static.built: $(BUILD)/libjpeg-turbo.built $(BUILD)/libpng.built $(BUILD)/SDL2_image.built $(BUILD)/SDL2_mixer.built
	$(SCRIPTSDIR)/pygame_sdl2-static.sh
	touch $(BUILD)/pygame_sdl2-static.built

$(BUILD)/pygame_sdl2-dynamic.built: $(BUILD)/libjpeg-turbo.built $(BUILD)/libpng.built $(BUILD)/SDL2_image.built $(BUILD)/SDL2_mixer.built
	$(SCRIPTSDIR)/pygame_sdl2-dynamic.sh
	touch $(BUILD)/pygame_sdl2-dynamic.built

$(BUILD)/libjpeg-turbo.built: $(CACHEROOT)/libjpeg-turbo-1.4.0.tar.gz
	$(SCRIPTSDIR)/libjpeg-turbo.sh
	touch $(BUILD)/libjpeg-turbo.built

$(BUILD)/libpng.built: $(CACHEROOT)/libpng-1.6.34.tar.gz $(BUILD)/zlib.built
	$(SCRIPTSDIR)/libpng.sh
	touch $(BUILD)/libpng.built

$(BUILD)/zlib.built: $(CACHEROOT)/zlib-1.2.11.tar.gz
	$(SCRIPTSDIR)/zlib.sh
	touch $(BUILD)/zlib.built

$(BUILD)/libzip.built: $(CACHEROOT)/libzip-1.5.1.tar.gz
	$(SCRIPTSDIR)/libzip.sh
	touch $(BUILD)/libzip.built

# Note: do not mix USE_SDL_IMAGE=2 (2.0.0 and -lSDL2_image (2.0.2)
# I got weird errors with dynamic linking, possibly they are not 100% compatible
$(BUILD)/SDL2_image.built: $(CACHEROOT)/SDL2_image-2.0.2.tar.gz
	$(SCRIPTSDIR)/SDL2_image.sh
	touch $(BUILD)/SDL2_image.built

# Note: SDL2_mixer needed for pygame_sdl2's headers / initial compilation;
# there's a new USE_SDL_MIXER=2 but its .h is not installed properly
$(BUILD)/SDL2_mixer.built: $(CACHEROOT)/SDL2_mixer-2.0.1.tar.gz
	$(SCRIPTSDIR)/SDL2_mixer.sh
	touch $(BUILD)/SDL2_mixer.built

$(CACHEROOT)/libjpeg-turbo-1.4.0.tar.gz:
	wget https://sourceforge.net/projects/libjpeg-turbo/files/1.4.0/libjpeg-turbo-1.4.0.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/libpng-1.6.34.tar.gz:
	wget http://prdownloads.sourceforge.net/libpng/libpng-1.6.34.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/fribidi-0.19.2.tar.gz:
	wget https://web.archive.org/web/20160305193708/http://fribidi.org/download/fribidi-0.19.2.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/ffmpeg-3.0.tar.bz2:
	wget https://ffmpeg.org/releases/ffmpeg-3.0.tar.bz2 -P $(CACHEROOT)

#$(BUILD)/SDL2.built: $(CACHEROOT)/SDL2-2.0.8.tar.gz
#	$(SCRIPTSDIR)/sdl2.sh
#	touch $(BUILD)/sdl2.built
#
#$(CACHEROOT)/SDL2-2.0.8.tar.gz:
#	wget https://libsdl.org/release/SDL2-2.0.8.tar.gz -P $(CACHEROOT)
# => USE_SDL=2 for now, it has lots of Emscripten fixes

$(BUILD)/SDL2.built:
	-git clone https://github.com/emscripten-ports/SDL2 $(BUILD)/SDL2
	cd $(BUILD)/SDL2; \
                git checkout version_17; \
                patch -p1 < $(PATCHESDIR)/SDL2-emterpreter.patch; \
	touch $(BUILD)/SDL2.built

# TODO: move to 2.0.3 but depends on latest SDL2 (> USE_SDL=2 port)
$(CACHEROOT)/SDL2_image-2.0.2.tar.gz:
	wget http://libsdl.org/projects/SDL_image/release/SDL2_image-2.0.2.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/SDL2_mixer-2.0.1.tar.gz:
	wget http://libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.1.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/zlib-1.2.11.tar.gz:
	wget http://prdownloads.sourceforge.net/libpng/zlib-1.2.11.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/libzip-1.5.1.tar.gz:
	wget https://libzip.org/download/libzip-1.5.1.tar.gz -P $(CACHEROOT)
