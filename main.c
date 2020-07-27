/*
RenPyWeb entry point - load and start Python

Copyright (C) 2019, 2020  Sylvain Beucler
Copyright (C) 2020  Tom Rothamel

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
#include <Python.h>
#include <stdio.h>
#include <SDL2/SDL.h>

#if PY_MAJOR_VERSION >= 3
#define MODINIT(name) PyInit_##name
#else
#define MODINIT(name) init##name
#endif

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/html5.h>
#endif
#if defined(__EMSCRIPTEN__) || defined(MOCK)
PyMODINIT_FUNC MODINIT(emscripten)(void);
#endif

void pyapp_runmain();


#ifdef STATIC
PyMODINIT_FUNC MODINIT(pygame_sdl2_color)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_controller)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_display)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_draw)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_error)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_event)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_event)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_image)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_joystick)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_key)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_locals)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_mouse)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_power)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_pygame_time)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_rect)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_rwobject)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_scrap)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_surface)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_transform)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_gfxdraw)(void);
#  ifndef RENPY
PyMODINIT_FUNC MODINIT(pygame_sdl2_font)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_mixer)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_mixer_music)(void);
PyMODINIT_FUNC MODINIT(pygame_sdl2_render)(void);
#  endif

#  ifdef RENPY
PyMODINIT_FUNC MODINIT(_renpy)(void);
PyMODINIT_FUNC MODINIT(_renpybidi)(void);
PyMODINIT_FUNC MODINIT(renpy_audio_renpysound)(void);
PyMODINIT_FUNC MODINIT(renpy_parsersupport)(void);
PyMODINIT_FUNC MODINIT(renpy_pydict)(void);
PyMODINIT_FUNC MODINIT(renpy_style)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_styleclass)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_stylesets)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_activate_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_hover_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_idle_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_insensitive_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_selected_activate_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_selected_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_selected_hover_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_selected_idle_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_styledata_style_selected_insensitive_functions)(void);
PyMODINIT_FUNC MODINIT(renpy_display_matrix)(void);
PyMODINIT_FUNC MODINIT(renpy_display_render)(void);
PyMODINIT_FUNC MODINIT(renpy_display_accelerator)(void);
PyMODINIT_FUNC MODINIT(renpy_gl_gl)(void);
//PyMODINIT_FUNC MODINIT(renpy_gl_gl1)(void);
PyMODINIT_FUNC MODINIT(renpy_gl_gldraw)(void);
PyMODINIT_FUNC MODINIT(renpy_gl_gltexture)(void);
PyMODINIT_FUNC MODINIT(renpy_gl_glenviron_shader)(void);
//PyMODINIT_FUNC MODINIT(renpy_gl_glenviron_fixed)(void);
//PyMODINIT_FUNC MODINIT(renpy_gl_glenviron_limited)(void);
PyMODINIT_FUNC MODINIT(renpy_gl_glrtt_copy)(void);
PyMODINIT_FUNC MODINIT(renpy_gl_glrtt_fbo)(void);
PyMODINIT_FUNC MODINIT(renpy_text_textsupport)(void);
PyMODINIT_FUNC MODINIT(renpy_text_texwrap)(void);
PyMODINIT_FUNC MODINIT(renpy_text_ftfont)(void);
#  endif
#endif

int main(int argc, char* argv[]) {
	// Load additional modules installed relative to current directory
	// Note: Python already looks for a PYTHONHOME structure in '.' by default
	setenv("PYTHONPATH", ".", 0);
	// Trace GL calls and throw exception on error
	//setenv("RENPY_GL_CHECK_ERRORS", "7", 0);
	// Force using FrameBufferObjects for RenderToTexture
	//setenv("RENPY_GL_RTT", "fbo", 1);
	// Logs all SDL_SetError (at least in SDL 2.0.5)
	//SDL_LogSetAllPriority(SDL_LOG_PRIORITY_DEBUG);

	Py_FrozenFlag   = 1; // drop <exec_prefix> warnings
	Py_OptimizeFlag = 2; // look for .pyo rather than .pyc
	Py_VerboseFlag  = 1; // trace modules loading

	//initemscripten();
	static struct _inittab builtins[] = {
#if defined(__EMSCRIPTEN__) || defined(MOCK)
	  {"emscripten", MODINIT(emscripten)},
#endif
#ifdef STATIC
	  {"pygame_sdl2.event", MODINIT(pygame_sdl2_event)},
	  {"pygame_sdl2.error", MODINIT(pygame_sdl2_error)},
	  {"pygame_sdl2.color", MODINIT(pygame_sdl2_color)},
	  {"pygame_sdl2.controller", MODINIT(pygame_sdl2_controller)},
	  {"pygame_sdl2.rect", MODINIT(pygame_sdl2_rect)},
	  {"pygame_sdl2.rwobject", MODINIT(pygame_sdl2_rwobject)},
	  {"pygame_sdl2.surface", MODINIT(pygame_sdl2_surface)},
	  {"pygame_sdl2.display", MODINIT(pygame_sdl2_display)},
	  {"pygame_sdl2.event", MODINIT(pygame_sdl2_event)},
	  {"pygame_sdl2.locals", MODINIT(pygame_sdl2_locals)},
	  {"pygame_sdl2.key", MODINIT(pygame_sdl2_key)},
	  {"pygame_sdl2.mouse", MODINIT(pygame_sdl2_mouse)},
	  {"pygame_sdl2.joystick", MODINIT(pygame_sdl2_joystick)},
	  {"pygame_sdl2.power", MODINIT(pygame_sdl2_power)},
	  {"pygame_sdl2.pygame_time", MODINIT(pygame_sdl2_pygame_time)},
	  {"pygame_sdl2.image", MODINIT(pygame_sdl2_image)},
	  {"pygame_sdl2.transform", MODINIT(pygame_sdl2_transform)},
	  {"pygame_sdl2.gfxdraw", MODINIT(pygame_sdl2_gfxdraw)},
	  {"pygame_sdl2.draw", MODINIT(pygame_sdl2_draw)},
#  ifndef RENPY
	  {"pygame_sdl2.font", MODINIT(pygame_sdl2_font)},
	  {"pygame_sdl2.mixer", MODINIT(pygame_sdl2_mixer)},
	  {"pygame_sdl2.mixer_music", MODINIT(pygame_sdl2_mixer_music)},
#  endif
	  {"pygame_sdl2.scrap", MODINIT(pygame_sdl2_scrap)},
#  ifndef RENPY
	  {"pygame_sdl2.render", MODINIT(pygame_sdl2_render)},
#  endif

#  ifdef RENPY
	  {"_renpy", MODINIT(_renpy)},
	  {"_renpybidi", MODINIT(_renpybidi)},
	  {"renpy.audio.renpysound", MODINIT(renpy_audio_renpysound)},
	  {"renpy.parsersupport", MODINIT(renpy_parsersupport)},
	  {"renpy.pydict", MODINIT(renpy_pydict)},
	  {"renpy.style", MODINIT(renpy_style)},
	  {"renpy.styledata.styleclass", MODINIT(renpy_styledata_styleclass)},
	  {"renpy.styledata.stylesets", MODINIT(renpy_styledata_stylesets)},
	  {"renpy.styledata.style_activate_functions", MODINIT(renpy_styledata_style_activate_functions)},
	  {"renpy.styledata.style_functions", MODINIT(renpy_styledata_style_functions)},
	  {"renpy.styledata.style_hover_functions", MODINIT(renpy_styledata_style_hover_functions)},
	  {"renpy.styledata.style_idle_functions", MODINIT(renpy_styledata_style_idle_functions)},
	  {"renpy.styledata.style_insensitive_functions", MODINIT(renpy_styledata_style_insensitive_functions)},
	  {"renpy.styledata.style_selected_activate_functions", MODINIT(renpy_styledata_style_selected_activate_functions)},
	  {"renpy.styledata.style_selected_functions", MODINIT(renpy_styledata_style_selected_functions)},
	  {"renpy.styledata.style_selected_hover_functions", MODINIT(renpy_styledata_style_selected_hover_functions)},
	  {"renpy.styledata.style_selected_idle_functions", MODINIT(renpy_styledata_style_selected_idle_functions)},
	  {"renpy.styledata.style_selected_insensitive_functions", MODINIT(renpy_styledata_style_selected_insensitive_functions)},
	  {"renpy.display.matrix", MODINIT(renpy_display_matrix)},
	  {"renpy.display.render", MODINIT(renpy_display_render)},
	  {"renpy.display.accelerator", MODINIT(renpy_display_accelerator)},
	  {"renpy.gl.gl", MODINIT(renpy_gl_gl)},
	  //{"renpy.gl.gl1", MODINIT(renpy_gl_gl1)},
	  {"renpy.gl.gldraw", MODINIT(renpy_gl_gldraw)},
	  {"renpy.gl.gltexture", MODINIT(renpy_gl_gltexture)},
	  {"renpy.gl.glenviron_shader", MODINIT(renpy_gl_glenviron_shader)},
	  //{"renpy.gl.glenviron_fixed", MODINIT(renpy_gl_glenviron_fixed)},
	  //{"renpy.gl.glenviron_limited", MODINIT(renpy_gl_glenviron_limited)},
	  {"renpy.gl.glrtt_copy", MODINIT(renpy_gl_glrtt_copy)},
	  {"renpy.gl.glrtt_fbo", MODINIT(renpy_gl_glrtt_fbo)},
	  {"renpy.text.textsupport", MODINIT(renpy_text_textsupport)},
	  {"renpy.text.texwrap", MODINIT(renpy_text_texwrap)},
	  {"renpy.text.ftfont", MODINIT(renpy_text_ftfont)},
#  endif
#endif
	  {NULL, NULL}
	};
	PyImport_ExtendInittab(builtins);
	Py_InitializeEx(0);  // 0 = get rid of 'Calling stub instead of sigaction()'

#if PY_MAJOR_VERSION >= 3
	//PySys_SetArgv(argc, argv); // argv is now wchar_t **, triggers fatal error
#else
	PySys_SetArgv(argc, argv);
#endif

	// Static submodules support
#if PY_MAJOR_VERSION >= 3
        // https://github.com/dgym/cpython-emscripten/blob/master/examples/06-cython-packages/main.c
	PyRun_SimpleString(
			   "import importlib.abc\n"		\
			   "import importlib.machinery\n"	\
			   "import sys\n"			\
			   "\n"					\
			   "\n"					\
			   "class Finder(importlib.abc.MetaPathFinder):\n" \
			   "    def find_spec(self, fullname, path, target=None):\n" \
			   "        if fullname in sys.builtin_module_names:\n" \
			   "            return importlib.machinery.ModuleSpec(\n" \
			   "                fullname,\n"		\
			   "                importlib.machinery.BuiltinImporter,\n" \
			   "            )\n"				\
			   "\n"						\
			   "\n"						\
			   "sys.meta_path.append(Finder())\n"		\
			   );
#else
	// Patched Py2 and/or:
	PyRun_SimpleString(
			   "import imp\n"                                              \
			   "import sys\n"                                              \
			   "\n"	                                                       \
			   "class BuiltinSubmoduleImporter(object):\n"                 \
			   "\n"	                                                       \
			   "    def find_module(self, name, path=None):\n"             \
			   "        if path is None:\n"                                \
			   "            return None\n"                                 \
			   "\n"                                                        \
			   "        if '.' not in name:\n"                             \
			   "            return None\n"                                 \
			   "\n"                                                        \
			   "        if name in sys.builtin_module_names:\n"            \
			   "            return self\n"                                 \
			   "\n"                                                        \
			   "        return None\n"                                     \
			   "\n"                                                        \
			   "    def load_module(self, name):\n"                        \
			   "        f, pathname, desc = imp.find_module(name, None)\n" \
			   "        return imp.load_module(name, f, pathname, desc)\n" \
			   "\n"                                                        \
			   "sys.meta_path.append(BuiltinSubmoduleImporter())\n"        \
			   );
#endif
	PyRun_SimpleString("print('Python loaded.')");

#if __EMSCRIPTEN__ && RENPY
	// Return without exiting so we can keep using Python
	emscripten_exit_with_live_runtime();
#elif __EMSCRIPTEN__
	// pygame-example
	pyapp_runmain();
#else
	// Mock Emscripten
	pyapp_runmain();
#endif
}


void pyapp_runmain() {
  FILE* f = fopen("main.py", "rb");
  if (f == NULL) {
    perror("fopen");
    printf("Cannot find application entry point (main.py). Invalid filesystem image?\n");
    return;
  }
#ifdef __EMSCRIPTEN__
  // Doesn't seem to print before the end of the load, maybe requires
  // fflush - moving to JavaScript so we're sure it's printed timely.
  // Also we have the presplash image now.
  //printf("Loading game, please wait...\n");
  //emscripten_sleep(0);
#endif
  
  int ret = PyRun_SimpleFileEx(f, "main.py", 1);
  //Module['quit'] will be called and display "Quit"
  //printf("Game completed.\n");

  //if (ret)
  //  printf("Exit code %d.\n", ret);
  
  // De-init Python
  //Py_Finalize();
}
