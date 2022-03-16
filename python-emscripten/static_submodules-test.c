#include <Python.h>
#include <stdio.h>

PyMODINIT_FUNC inittestmod_testsubmod(void); /*proto*/

int main(void) {
        // Trace modules loading
        //setenv("PYTHONVERBOSE", "1", 0);
        // Load additional modules installed relative to current directory
        setenv("PYTHONPATH", ".", 0);

	Py_InitializeEx(0);

	//inittestmod_testsubmod();
	static struct _inittab builtins[] = {
	  {"testmod.testsubmod", inittestmod_testsubmod},
	  {NULL, NULL}
	};
	PyImport_ExtendInittab(builtins);

	PyRun_SimpleString("import testmod.testsubmod; testmod.testsubmod.myputs()");
	Py_Finalize();
}

/*

cat <<'EOF' > testmod/testsubmod.pyx
cdef extern from "stdio.h":
    int puts(const char *s);

def myputs():
    puts("\n\nHELLOOOOOOOOOO\n\n");
EOF

cython testmod/testsubmod.pyx
sed -i -e 's|Py_InitModule4("\([^"]\+\)"|Py_InitModule4("testmod.\1"|' \
       -e 's|^__Pyx_PyMODINIT_FUNC init|__Pyx_PyMODINIT_FUNC inittestmod_|' testmod/testsubmod.c
gcc -I../../Include -I.. testmod/testsubmod.c main.c ../libpython2.7.a -lm -ldl -lutil && ./a.out 

See also https://mdqinc.com/blog/2011/08/statically-linking-python-with-cython-generated-modules-and-packages/

*/
