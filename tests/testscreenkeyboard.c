#include <SDL2/SDL.h>
#include <math.h>
#include <stdio.h>

int main(int argc, char* argv[]) {
  printf("starting...\n");
  printf("sizeof(float): %lu\n", sizeof(float));
  printf("sizeof(double): %lu\n", sizeof(double));

  if (SDL_Init(SDL_INIT_VIDEO)) {
    fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
    return 1;
  }

  printf("SDL_HasScreenKeyboardSupport=%d\n", SDL_HasScreenKeyboardSupport());

  SDL_Quit();
  printf("end.\n");
}

/**
 * Local Variables:
 * compile-command: "emcc testscreenkeyboard.c -s USE_SDL=2 -o t/testscreenkeyboard.html"
 * End:
 */
