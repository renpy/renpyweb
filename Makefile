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

PYGAME_SDL2_STATIC_OBJS=pygame_sdl2/emscripten-static/build-temp/gen-static/*.o pygame_sdl2/emscripten-static/build-temp/src/*.o

RENPY_OBJS=$(BUILD)/main-renpyweb-static.bc $(BUILD)/importexport.bc \
	$(PYGAME_SDL2_STATIC_OBJS) \
	renpy/module/emscripten-static/build-temp/*.o renpy/module/emscripten-static/build-temp/gen-static/*.o

COMMON_LDFLAGS = \
	-L $(INSTALLDIR)/lib $(LDFLAGS) \
	$(BUILD)/emscripten.bc \
	-s EMULATE_FUNCTION_POINTER_CASTS=1 \
	-s FORCE_FILESYSTEM=1 -s LZ4=1 \
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
# Last-resort stack trace inspection: manually console.trace() before the emscripten_sleep()s
ASYNCIFY_LDFLAGS = \
	-s ASYNCIFY=1 -s ASYNCIFY_STACK_SIZE=65535 \
	-s ASYNCIFY_WHITELIST='["main", "pyapp_runmain", "async_callback", "byn$$fpcast-emu$$async_callback", "SDL_WaitEvent", "SDL_WaitEventTimeout", "SDL_Delay", "SDL_RenderPresent", "GLES2_RenderPresent", "SDL_GL_SwapWindow", "Emscripten_GLES_SwapWindow", "byn$$fpcast-emu$$Emscripten_GLES_SwapWindow", "SDL_UpdateWindowSurface", "SDL_UpdateWindowSurfaceRects", "Emscripten_UpdateWindowFramebuffer", "PyRun_SimpleFileExFlags", "PyRun_FileExFlags", "PyEval_EvalCode", "PyEval_EvalCodeEx", "PyEval_EvalFrameEx", "PyCFunction_Call", "PyObject_Call", "fast_function", "byn$$fpcast-emu$$function_call", "function_call", "instancemethod_call", "byn$$fpcast-emu$$instancemethod_call", "byn$$fpcast-emu$$slot_tp_call", "slot_tp_call", "__pyx_pw_11pygame_sdl2_5event_7wait", "byn$$fpcast-emu$$__pyx_pw_11pygame_sdl2_5event_7wait", "__pyx_pw_11pygame_sdl2_7display_21flip", "byn$$fpcast-emu$$__pyx_pw_11pygame_sdl2_7display_21flip", "__pyx_pw_11pygame_sdl2_7display_6Window_13flip", "byn$$fpcast-emu$$__pyx_pw_11pygame_sdl2_7display_6Window_13flip", "__pyx_pf_5renpy_2gl_6gldraw_6GLDraw_*draw_screen", "__pyx_pw_5renpy_2gl_6gldraw_6GLDraw_*draw_screen", "byn$$fpcast-emu$$__pyx_pw_5renpy_2gl_6gldraw_6GLDraw_*draw_screen", "__Pyx_PyObject_CallNoArg*", "byn$$fpcast-emu$$__pyx_pw_10emscripten_*sleep", "__pyx_pf_10emscripten_*sleep", "__pyx_pw_10emscripten_*sleep", "__pyx_pf_10emscripten_*sleep_with_yield", "__pyx_pw_10emscripten_*sleep_with_yield", "gen_send", "gen_send_ex", "gen_iternext", "type_call", "slot_tp_init", "builtin_eval"]'

COMMON_PYGAME_EXAMPLE_LDFLAGS = \
	    -s USE_SDL_MIXER=2 \
	    -s USE_SDL_TTF=2
RENPY_LDFLAGS = \
	$(COMMON_LDFLAGS) \
	-s USE_FREETYPE=1 \
	-lavformat -lavcodec -lavutil -lswresample -lswscale -lfribidi \
	-lzip \
	-s EXPORTED_FUNCTIONS='["_main", "_Py_Initialize", "_PyRun_SimpleString", "_pyapp_runmain", "_emSavegamesImport", "_emSavegamesExport"]' \
	-s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
	-s FULL_ES2=1 \
	--shell-file renpy-shell.html --pre-js renpy-pre.js

# No SDL2_mixer nor SDL2_ttf, Ren'Py has its own audio/ttf support.
# Compile our own SDL2_image because Emscripten has no webp ports and a different libjpeg.

#	EMCC_FORCE_STDLIBS=gl -> attempt to force GL symbols
#	-s SDL2_IMAGE_FORMATS='["png","jpg","webp"]' -> not compiling properly + expect conflicts with direct uses of libjpg/libpng from pygame_sdl2

# OpenGL: deprecated client-side buffers, not a single use of
# glGenBuffers or glBindBuffer in all of Ren'Py (boo)...
# -s FULL_ES2=1

# LZ4: support file_packager.py --lz4 (beware: creates read-only files, stored compressed in-memory)
# -s LZ4=1

# Debug:
# compilation process: EMCC_DEBUG=2
# webgl tracing: -s GL_ASSERTIONS=1 -s GL_UNSAFE_OPTS=0 -s TRACE_WEBGL_CALLS=1 -s GL_DEBUG=1

# Dynamic compilation:
# -s MAIN_MODULE=1
# .so-s with -s SIDE_MODULE=1 -s EXPORT_ALL=1
#   if you want to set WASM=0 -> need to recompile all the Python .so-s
# 1.39.0 still has several issues with dynamic linking, including linking -fPIC in static projects

# Memory usage
# TOTAL_MEMORY=64MB is not enough to run 'the_question' and 'tutorial'
# (2019-10, with --no-heap-copy so without filesystem; minimal Python fits in ~6MB)
# TOTAL_MEMORY=96MB works for 'the_question' and 'tutorial'; beware: memory growth is x2
# TOTAL_MEMORY=128MB leaves a nice margin
# TOTAL_MEMORY=512MB usually won't run at all on mobile platforms and/or picky browsers
# ALLOW_MEMORY_GROWTH=1 so we can run any game; documented as efficient with WASM

# - library_egl.js: don't put emscripten_sleep calls there (JS is non-emterpreted)


dirs:
	mkdir -p $(BUILD)/t/

$(BUILD)/emscripten.bc: $(BUILD)/python.built python-emscripten/emscripten.pyx
	cython -2 python-emscripten/emscripten.pyx -o $(BUILD)/emscripten.c
	emcc $(BUILD)/emscripten.c -o $(BUILD)/emscripten.bc -I install/include/python2.7

$(BUILD)/main-pygame_sdl2-static.bc: main.c
	emcc $(CFLAGS) -DSTATIC=1 main.c -o $(BUILD)/main-pygame_sdl2-static.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/main-pygame_sdl2-static-async.bc: main.c
	emcc $(CFLAGS) -DASYNC=1 -DSTATIC=1 main.c -o $(BUILD)/main-pygame_sdl2-static-async.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/main-pygame_sdl2-dynamic.bc: main.c
	emcc $(CFLAGS) main.c -o $(BUILD)/main-pygame_sdl2-dynamic.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/main-renpyweb-static.bc: main.c
	emcc $(CFLAGS) -DASYNC=1 -DSTATIC=1 -DRENPY=1 main.c -o $(BUILD)/main-renpyweb-static.bc -s USE_SDL=2 -I install/include/python2.7
$(BUILD)/importexport.bc: importexport.c $(BUILD)/libzip.built
	emcc $(CFLAGS) importexport.c -o $(BUILD)/importexport.bc -I install/include/

common: check_emscripten dirs $(BUILD)/emscripten.bc $(BUILD)/SDL2.built
common-pygame-example-static: common $(BUILD)/pygame_sdl2-static.built package-pygame-example-static
common-pygame-example-dynamic: common $(BUILD)/pygame_sdl2-dynamic.built $(BUILD)/main-pygame_sdl2-dynamic.bc

common-renpyweb: common $(BUILD)/main-renpyweb-static.bc $(BUILD)/importexport.bc package-renpyweb $(BUILD)/zee.js.built

package-python-minimal:
	PREFIX=$(INSTALLDIR) \
	  OUTDIR=$(BUILD)/t \
	  python-emscripten/2.7.10/package-pythonhome.sh
package-pygame-example-static: package-python-minimal
	$(CURDIR)/scripts/package-pyapp-pygame-example-static.sh
package-pygame-example-dynamic: package-python-minimal $(BUILD)/pygame_sdl2-dynamic.built
	$(CURDIR)/scripts/package-pyapp-pygame-example-dynamic.sh

package-renpyweb:
	# repr.py: for Developer mode > Variable viewer
	# encodings/raw_unicode_escape.py base64.py: for Ren'Py's tutorial
	# encodings/utf-32-be.py: .rpy from Ren'Py 6.x
	# encoding/ascii.py: for presplash?
	# webbrowser.py + shlex.py dep: click on URLs within Ren'Py
	# socket.py: websockets + urllib dependency
	# urllib.py: urllib.urlencode useful for encoding POST data
	# wave.py sunau.py chunk.py: for AudioData()
	PREFIX=$(INSTALLDIR) \
	  OUTDIR=$(BUILD)/t \
	  python-emscripten/2.7.10/package-pythonhome.sh \
	  repr.py \
	  encodings/raw_unicode_escape.py base64.py \
	  encodings/utf_32_be.py \
	  encodings/ascii.py \
	  webbrowser.py shlex.py \
	  socket.py \
	  urllib.py \
	  wave.py sunau.py chunk.py
	$(CURDIR)/scripts/package-pyapp-renpy.sh


##
# pygame-example for faster configuration experiments
##
pygame-example-static: $(BUILD)/python.built common-pygame-example-static $(BUILD)/main-pygame_sdl2-static.bc
	emcc $(BUILD)/main-pygame_sdl2-static.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html
pygame-example-static-asyncify: $(BUILD)/python.built common-pygame-example-static $(BUILD)/main-pygame_sdl2-static-async.bc
	emcc $(BUILD)/main-pygame_sdl2-static-async.bc \
	    $(PYGAME_SDL2_STATIC_OBJS) \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    $(ASYNCIFY_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html
#pygame-example-dynamic-asyncify: TODO
pygame-example-dynamic: $(BUILD)/python.built common-pygame-example-dynamic package-pygame-example-dynamic
	emcc $(BUILD)/main-pygame_sdl2-dynamic.bc \
	    -s MAIN_MODULE=1 -s EXPORT_ALL=1 \
	    $(COMMON_LDFLAGS) \
	    $(COMMON_PYGAME_EXAMPLE_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    --shell-file pygame-example-shell.html \
	    -o $(BUILD)/t/index.html
pygame-example-worker: $(BUILD)/python.built common-pygame-example-static
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


##
# renpyweb-static-asyncify
##
asyncify: $(BUILD)/python.built $(BUILD)/renpy.built common-renpyweb versionmark
	EMCC_LOCAL_PORTS=sdl2=$(BUILD)/SDL2 emcc $(RENPY_OBJS) \
	    $(RENPY_LDFLAGS) \
	    $(ASYNCIFY_LDFLAGS) \
	    -s TOTAL_MEMORY=128MB -s ALLOW_MEMORY_GROWTH=1 \
	    -o $(BUILD)/t/index.html
	# fallback compression
	cp -a $(BUILD)/zee.js/zee.js $(BUILD)/t/
	gzip -f $(BUILD)/t/index.wasm


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
	# Init emscripten libs (binaryen) outside of emconfigure so it won't complain
	tmpdir=$$(mktemp -d) && (cd $$tmpdir && echo 'int main(void){}' > tmp.c && emcc tmp.c) && rm -rf $$tmpdir

versionmark:
	git describe --tags --dirty > $(BUILD)/t/renpyweb-version.txt

# Compress and factor files before uploading to a decent host
# (note: gzip broken for itch.io/newgrounds though)
preupload-clean:
	rm -f \
		$(BUILD)/t/index.js.orig.js \
		$(BUILD)/t/index.wasm.pre $(BUILD)/t/index.wast \
		$(BUILD)/t/index.bc
	sed -i -e 's/%%TITLE%%/RenPyWeb/' $(BUILD)/t/index.html $(BUILD)/t/asmjs.html

hosting-gzip: preupload-clean
	-bash -c "gzip -f $(BUILD)/t/index.{em,js,html}"
	-bash -c "gzip -f $(BUILD)/t/pythonhome{.data,-data.js}"
	-bash -c "gzip -f $(BUILD)/t/pyapp{.data,-data.js}"
	-bash -c "gzip -f $(BUILD)/t/asmjs.{em,html,html.mem,js}"
	-gzip -f $(BUILD)/t/zee.js
	cp -a htaccess.txt $(BUILD)/t/.htaccess

gunzip:
	-bash -c "gunzip $(BUILD)/t/index.{em,js,html}.gz"
	-bash -c "gunzip $(BUILD)/t/pythonhome{.data,-data.js}.gz"
	-bash -c "gunzip $(BUILD)/t/pyapp{.data,-data.js}.gz"
	-bash -c "gunzip $(BUILD)/t/asmjs.{em,html,html.mem,js}.gz"
	-gunzip $(BUILD)/t/zee.js.gz
	rm -f $(BUILD)/t/.htaccess

testserver:
	(cd build/t && python3 $(CURDIR)/testserver.py)

cythonclean:
	rm -rf pygame_sdl2/*-static/ renpy/module/*-static/ build/pygame_sdl2-static.built build/renpy.built


$(BUILD)/python.built:
	$(MAKE) check_emscripten dirs  # not a dep so that we don't rebuild Python every time
	if [ ! -d python-emscripten ]; then \
	    fossil clone https://www.beuc.net/python-emscripten/python python-emscripten.fossil; \
	    mkdir python-emscripten; \
	    cd python-emscripten; \
	    fossil open ../python-emscripten.fossil 4c22eafeb3; \
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
	# Video currently unavailable, let's optimize size and (compilation) speed
	#$(SCRIPTSDIR)/ffmpeg.sh
	$(SCRIPTSDIR)/ffmpeg-audioonly.sh
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

$(BUILD)/libzip.built: $(CACHEROOT)/libzip-1.5.2.tar.gz
	$(SCRIPTSDIR)/libzip.sh
	touch $(BUILD)/libzip.built

$(BUILD)/zee.js.built:
	-git clone https://github.com/kripken/zee.js $(BUILD)/zee.js
	cd $(BUILD)/zee.js && \
		git checkout 4324d2ca65ced2c7e75d85baf6bdab11ccfed8ac && \
		make clean && \
		make -j$(nproc)
	touch $(BUILD)/zee.js.built

$(BUILD)/SDL2.built:
	-git clone --depth 1 --branch version_18 https://github.com/emscripten-ports/SDL2 $(BUILD)/SDL2
	cd $(BUILD)/SDL2 && \
		patch -p1 < $(PATCHESDIR)/SDL2-pseudosync.patch && \
		patch -p1 < $(PATCHESDIR)/SDL2-beforeunload.patch
	touch $(BUILD)/SDL2.built

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

#$(CACHEROOT)/SDL2-2.0.9.tar.gz:
#	wget https://libsdl.org/release/SDL2-2.0.9.tar.gz -P $(CACHEROOT)
# => USE_SDL=2 for now, it has lots of Emscripten fixes

$(CACHEROOT)/SDL2_image-2.0.2.tar.gz:
	wget https://libsdl.org/projects/SDL_image/release/SDL2_image-2.0.2.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/SDL2_mixer-2.0.1.tar.gz:
	wget https://libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.1.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/zlib-1.2.11.tar.gz:
	wget http://prdownloads.sourceforge.net/libpng/zlib-1.2.11.tar.gz -P $(CACHEROOT)

$(CACHEROOT)/libzip-1.5.2.tar.gz:
	wget https://libzip.org/download/libzip-1.5.2.tar.gz -P $(CACHEROOT)
