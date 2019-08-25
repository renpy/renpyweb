#include <math.h>
#include <stdio.h>
#include <emscripten.h>
#include <stdbool.h>

bool running = false;

//typedef void (*em_arg_callback_func)(void*)
static void callback(void *userdata) {
  if (running) {
    printf("callback\n");
    emscripten_async_call(callback, NULL, 1000);
  }
}

void test() {
  printf("before sleep...\n");

  // EMTERPRETER
  //emscripten_sleep_with_yield(5000);
  // ASYNCIFY
  emscripten_sleep(5000);

  printf("after sleep...\n");
}

int main(int argc, char* argv[]) {
  printf("starting...\n");
  running = true;

  emscripten_async_call(callback, NULL, 1000);

  test();

  running = false;
  printf("end.\n");
}

/* emcc ../testasync.c -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -o testasync.html */
/* emcc ../testasync.c -s ASYNCIFY -s ASYNCIFY_WHITELIST=['main','test'] -o testasync.html -g -s ASSERTIONS=2 */
