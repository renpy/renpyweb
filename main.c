/*
RenPyWeb entry point - load and start Python

Copyright (C) 2019  Sylvain Beucler

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

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/html5.h>
#endif
#if defined(__EMSCRIPTEN__) || defined(MOCK)
PyMODINIT_FUNC initemscripten(void);
#endif

void pyapp_runmain();


#ifdef STATIC
PyMODINIT_FUNC initpygame_sdl2_color(void);
PyMODINIT_FUNC initpygame_sdl2_controller(void);
PyMODINIT_FUNC initpygame_sdl2_display(void);
PyMODINIT_FUNC initpygame_sdl2_draw(void);
PyMODINIT_FUNC initpygame_sdl2_error(void);
PyMODINIT_FUNC initpygame_sdl2_event(void);
PyMODINIT_FUNC initpygame_sdl2_event(void);
PyMODINIT_FUNC initpygame_sdl2_image(void);
PyMODINIT_FUNC initpygame_sdl2_joystick(void);
PyMODINIT_FUNC initpygame_sdl2_key(void);
PyMODINIT_FUNC initpygame_sdl2_locals(void);
PyMODINIT_FUNC initpygame_sdl2_mouse(void);
PyMODINIT_FUNC initpygame_sdl2_power(void);
PyMODINIT_FUNC initpygame_sdl2_pygame_time(void);
PyMODINIT_FUNC initpygame_sdl2_rect(void);
PyMODINIT_FUNC initpygame_sdl2_rwobject(void);
PyMODINIT_FUNC initpygame_sdl2_scrap(void);
PyMODINIT_FUNC initpygame_sdl2_surface(void);
PyMODINIT_FUNC initpygame_sdl2_transform(void);
PyMODINIT_FUNC initpygame_sdl2_gfxdraw(void);
#  ifndef RENPY
PyMODINIT_FUNC initpygame_sdl2_font(void);
PyMODINIT_FUNC initpygame_sdl2_mixer(void);
PyMODINIT_FUNC initpygame_sdl2_mixer_music(void);
PyMODINIT_FUNC initpygame_sdl2_render(void);
#  endif

#  ifdef RENPY
PyMODINIT_FUNC init_renpy(void);
PyMODINIT_FUNC init_renpybidi(void);
PyMODINIT_FUNC initrenpy_audio_renpysound(void);
PyMODINIT_FUNC initrenpy_parsersupport(void);
PyMODINIT_FUNC initrenpy_pydict(void);
PyMODINIT_FUNC initrenpy_style(void);
PyMODINIT_FUNC initrenpy_styledata_styleclass(void);
PyMODINIT_FUNC initrenpy_styledata_stylesets(void);
PyMODINIT_FUNC initrenpy_styledata_style_activate_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_hover_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_idle_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_insensitive_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_selected_activate_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_selected_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_selected_hover_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_selected_idle_functions(void);
PyMODINIT_FUNC initrenpy_styledata_style_selected_insensitive_functions(void);
PyMODINIT_FUNC initrenpy_display_matrix(void);
PyMODINIT_FUNC initrenpy_display_render(void);
PyMODINIT_FUNC initrenpy_display_accelerator(void);
PyMODINIT_FUNC initrenpy_gl_gl(void);
//PyMODINIT_FUNC initrenpy_gl_gl1(void);
PyMODINIT_FUNC initrenpy_gl_gldraw(void);
PyMODINIT_FUNC initrenpy_gl_gltexture(void);
PyMODINIT_FUNC initrenpy_gl_glenviron_shader(void);
//PyMODINIT_FUNC initrenpy_gl_glenviron_fixed(void);
//PyMODINIT_FUNC initrenpy_gl_glenviron_limited(void);
PyMODINIT_FUNC initrenpy_gl_glrtt_copy(void);
PyMODINIT_FUNC initrenpy_gl_glrtt_fbo(void);
PyMODINIT_FUNC initrenpy_text_textsupport(void);
PyMODINIT_FUNC initrenpy_text_texwrap(void);
PyMODINIT_FUNC initrenpy_text_ftfont(void);
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
	Py_InitializeEx(0);  // 0 = get rid of 'Calling stub instead of sigaction()'

	//initemscripten();
	static struct _inittab builtins[] = {
#if defined(__EMSCRIPTEN__) || defined(MOCK)
	  {"emscripten", initemscripten},
#endif
#ifdef STATIC
	  {"pygame_sdl2.event", initpygame_sdl2_event},
	  {"pygame_sdl2.error", initpygame_sdl2_error},
	  {"pygame_sdl2.color", initpygame_sdl2_color},
	  {"pygame_sdl2.controller", initpygame_sdl2_controller},
	  {"pygame_sdl2.rect", initpygame_sdl2_rect},
	  {"pygame_sdl2.rwobject", initpygame_sdl2_rwobject},
	  {"pygame_sdl2.surface", initpygame_sdl2_surface},
	  {"pygame_sdl2.display", initpygame_sdl2_display},
	  {"pygame_sdl2.event", initpygame_sdl2_event},
	  {"pygame_sdl2.locals", initpygame_sdl2_locals},
	  {"pygame_sdl2.key", initpygame_sdl2_key},
	  {"pygame_sdl2.mouse", initpygame_sdl2_mouse},
	  {"pygame_sdl2.joystick", initpygame_sdl2_joystick},
	  {"pygame_sdl2.power", initpygame_sdl2_power},
	  {"pygame_sdl2.pygame_time", initpygame_sdl2_pygame_time},
	  {"pygame_sdl2.image", initpygame_sdl2_image},
	  {"pygame_sdl2.transform", initpygame_sdl2_transform},
	  {"pygame_sdl2.gfxdraw", initpygame_sdl2_gfxdraw},
	  {"pygame_sdl2.draw", initpygame_sdl2_draw},
#  ifndef RENPY
	  {"pygame_sdl2.font", initpygame_sdl2_font},
	  {"pygame_sdl2.mixer", initpygame_sdl2_mixer},
	  {"pygame_sdl2.mixer_music", initpygame_sdl2_mixer_music},
#  endif
	  {"pygame_sdl2.scrap", initpygame_sdl2_scrap},
#  ifndef RENPY
	  {"pygame_sdl2.render", initpygame_sdl2_render},
#  endif

#  ifdef RENPY
	  {"_renpy", init_renpy},
	  {"_renpybidi", init_renpybidi},
	  {"renpy.audio.renpysound", initrenpy_audio_renpysound},
	  {"renpy.parsersupport", initrenpy_parsersupport},
	  {"renpy.pydict", initrenpy_pydict},
	  {"renpy.style", initrenpy_style},
	  {"renpy.styledata.styleclass", initrenpy_styledata_styleclass},
	  {"renpy.styledata.stylesets", initrenpy_styledata_stylesets},
	  {"renpy.styledata.style_activate_functions", initrenpy_styledata_style_activate_functions},
	  {"renpy.styledata.style_functions", initrenpy_styledata_style_functions},
	  {"renpy.styledata.style_hover_functions", initrenpy_styledata_style_hover_functions},
	  {"renpy.styledata.style_idle_functions", initrenpy_styledata_style_idle_functions},
	  {"renpy.styledata.style_insensitive_functions", initrenpy_styledata_style_insensitive_functions},
	  {"renpy.styledata.style_selected_activate_functions", initrenpy_styledata_style_selected_activate_functions},
	  {"renpy.styledata.style_selected_functions", initrenpy_styledata_style_selected_functions},
	  {"renpy.styledata.style_selected_hover_functions", initrenpy_styledata_style_selected_hover_functions},
	  {"renpy.styledata.style_selected_idle_functions", initrenpy_styledata_style_selected_idle_functions},
	  {"renpy.styledata.style_selected_insensitive_functions", initrenpy_styledata_style_selected_insensitive_functions},
	  {"renpy.display.matrix", initrenpy_display_matrix},
	  {"renpy.display.render", initrenpy_display_render},
	  {"renpy.display.accelerator", initrenpy_display_accelerator},
	  {"renpy.gl.gl", initrenpy_gl_gl},
	  //{"renpy.gl.gl1", initrenpy_gl_gl1},
	  {"renpy.gl.gldraw", initrenpy_gl_gldraw},
	  {"renpy.gl.gltexture", initrenpy_gl_gltexture},
	  {"renpy.gl.glenviron_shader", initrenpy_gl_glenviron_shader},
	  //{"renpy.gl.glenviron_fixed", initrenpy_gl_glenviron_fixed},
	  //{"renpy.gl.glenviron_limited", initrenpy_gl_glenviron_limited},
	  {"renpy.gl.glrtt_copy", initrenpy_gl_glrtt_copy},
	  {"renpy.gl.glrtt_fbo", initrenpy_gl_glrtt_fbo},
	  {"renpy.text.textsupport", initrenpy_text_textsupport},
	  {"renpy.text.texwrap", initrenpy_text_texwrap},
	  {"renpy.text.ftfont", initrenpy_text_ftfont},
#  endif
#endif
	  {NULL, NULL}
	};
	PyImport_ExtendInittab(builtins);

	PySys_SetArgv(argc, argv);
	PyRun_SimpleString("print 'Python loaded.'");

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
