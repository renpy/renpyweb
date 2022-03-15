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

void init_librenpy();


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
	  {NULL, NULL}
	};

	PyImport_ExtendInittab(builtins);
	init_librenpy();

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

#if 0
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
