/**
 * Simple Python prompt with static emscripten module available
 * 
 * Copyright (C) 2019, 2020  Sylvain Beucler
 *
 * Copying and distribution of this file, with or without
 * modification, are permitted in any medium without royalty provided
 * the copyright notice and this notice are preserved.  This file is
 * offered as-is, without any warranty.
 */

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif
#include <Python.h>

#if PY_MAJOR_VERSION >= 3
#define MODINIT(name) PyInit_##name
#else
#define MODINIT(name) init##name
#endif

PyMODINIT_FUNC MODINIT(emscripten) (void);
PyMODINIT_FUNC MODINIT(emscripten_fetch) (void);

// Run a line *and* display the result
// PyRun_StringFlags only returns a non-None object with Py_eval_input (no 'print' support)
// PyRun_InteractiveOne always reads stdin even with another 'fp', so we redirect stdin
void pyruni() {
  freopen("/tmp/input.py", "rb", stdin);
  PyRun_InteractiveOne(stdin, "<stdin>");
}

int main(int argc, char**argv) {
  Py_OptimizeFlag = 2; // look for .pyo rather than .pyc
  Py_FrozenFlag   = 1; // drop <exec_prefix> warnings
  Py_VerboseFlag  = 1; // trace modules loading
  static struct _inittab builtins[] = {
    { "emscripten", MODINIT(emscripten) },
    { "emscripten_fetch", MODINIT(emscripten_fetch) },
    {NULL, NULL}
  };
  PyImport_ExtendInittab(builtins);
  Py_InitializeEx(0);  // 0 = get rid of 'Calling stub instead of sigaction()'
#ifdef __EMSCRIPTEN__
  emscripten_exit_with_live_runtime();
#else
  pyruni();
#endif
  return 0;
}
