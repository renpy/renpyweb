#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int
main(int argc,char** argv)
{
  void *h;
  void (*f)();
  h = dlopen("./testsidemodule.so", RTLD_NOW|RTLD_GLOBAL);
  printf("h=%p\n", h);
  f = dlsym(h, "f");
  if (f == NULL)
    printf("%s\n", dlerror());
  printf("f=%p\n", f);
  f();
  //dlclose(h);
  return 0;
}

// \cp -a testsidemodule.wasm testsidemodule.so
// emcc -s MAIN_MODULE=1 ../testmainmodule.c -o testmainmodule.html -s WASM=1 --preload-file testsidemodule.so
