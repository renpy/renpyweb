#include <SDL2/SDL.h>
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

int main(int argc, char* argv[]) {
  printf("starting...\n");
  running = true;

  if (SDL_Init(0)) {
    fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
    return 1;
  }

  emscripten_async_call(callback, NULL, 1000);
  //emscripten_sleep(5000);
  emscripten_sleep_with_yield(5000);

  running = false;
  printf("end.\n");
}

/* EMCC_LOCAL_PORTS="sdl2=$HOME/workdir/emsource/ports/SDL2-version_13|SDL2-version_13" emcc ../testasync.c -s USE_SDL=2 -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -o testasync.html */
