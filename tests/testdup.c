/**
 * Test case for duplicate click events on touch devices
 * https://github.com/emscripten-ports/SDL2/pull/64
 */
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif
#include "SDL.h"
static int run = 1;

void loop()
{
  SDL_Event event;
  while (SDL_PollEvent(&event)) {
    switch(event.type) {
    case SDL_MOUSEMOTION:
      SDL_Log("mousemotion %i\n", event.motion.which);
      break;
    case SDL_MOUSEBUTTONDOWN:
      SDL_Log("mousebuttondown %i\n", event.button.which);
      break;
    case SDL_MOUSEBUTTONUP:
      SDL_Log("mousebuttonup %i\n", event.button.which);
      break;

    case SDL_FINGERMOTION:
      SDL_Log("fingermotion %lli\n", event.tfinger.touchId);
      break;
    case SDL_FINGERDOWN:
      SDL_Log("fingerdown %lli\n", event.tfinger.touchId);
      break;
    case SDL_FINGERUP:
      SDL_Log("fingerup %lli\n", event.tfinger.touchId);
      break;
    case SDL_QUIT:
      run = 0;
      break;
    }
  }
}

int main(int argc, char *argv[])
{
  SDL_Window *window;

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    return (1);
  }

  window = SDL_CreateWindow("Test", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 640, 480, 0);

  SDL_EventState(SDL_FINGERDOWN, SDL_IGNORE);
  SDL_EventState(SDL_FINGERUP, SDL_IGNORE);
  SDL_EventState(SDL_FINGERMOTION, SDL_IGNORE);

#ifdef __EMSCRIPTEN__
  emscripten_set_main_loop(loop, 0, 1);
#else
  while (run) loop();
#endif

  return (0);
}

/**

Native Android:
mousemotion -1
mousebuttondown -1
mousebuttonup -1

emscripten SDL2 + Firefox Android:
mousemotion -1
mousebuttondown -1
mousebuttonup -1
mousemotion 0
mousebuttondown 0
mousebuttonup 0

*/
