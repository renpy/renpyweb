#include <stdio.h>
#include <emscripten.h>
void f(void) {
  printf("f1!\n");
  emscripten_sleep(5000);
  printf("f2!\n");
}

// emcc -s SIDE_MODULE=1 -s EXPORT_ALL=1                ../testsidemodule.c -o testsidemodule.wasm -s WASM=1
// emcc -s SIDE_MODULE=1 -s EXPORTED_FUNCTIONS="['_f']" ../testsidemodule.c -o testsidemodule.wasm -s WASM=1
